// ContractorLens Production Metrics Middleware
let AWS = null;
let cloudWatch = null;

try {
  AWS = require('aws-sdk');
  
  // Configure CloudWatch client
  cloudWatch = new AWS.CloudWatch({
    region: process.env.AWS_REGION || 'us-west-2'
  });
} catch (error) {
  console.warn('AWS SDK not available. Metrics will be logged locally only.');
  cloudWatch = null;
}

class MetricsService {
  constructor() {
    this.namespace = 'ContractorLens';
    this.environment = process.env.NODE_ENV || 'production';
    this.enabled = process.env.METRICS_ENABLED !== 'false';
    
    // In-memory metrics cache for batching
    this.metricsBuffer = [];
    this.bufferSize = 20; // CloudWatch limit
    this.flushInterval = 60000; // 1 minute
    
    if (this.enabled) {
      this.startPeriodicFlush();
    }
  }

  /**
   * Record custom metric
   * @param {string} metricName - Name of the metric
   * @param {number} value - Metric value
   * @param {string} unit - CloudWatch unit (Count, Seconds, Bytes, etc.)
   * @param {Object} dimensions - Additional dimensions
   */
  putMetric(metricName, value, unit = 'Count', dimensions = {}) {
    if (!this.enabled) return;

    const metric = {
      MetricName: metricName,
      Value: value,
      Unit: unit,
      Timestamp: new Date(),
      Dimensions: [
        {
          Name: 'Environment',
          Value: this.environment
        },
        ...Object.entries(dimensions).map(([name, value]) => ({
          Name: name,
          Value: String(value)
        }))
      ]
    };

    this.metricsBuffer.push(metric);

    // Flush if buffer is full
    if (this.metricsBuffer.length >= this.bufferSize) {
      this.flushMetrics();
    }
  }

  /**
   * Record API request metrics
   */
  recordAPIMetrics(req, res, responseTime) {
    const route = this.getRouteFromPath(req.path);
    const statusCode = res.statusCode;
    const method = req.method;

    // Request count
    this.putMetric('APIRequests', 1, 'Count', {
      Route: route,
      Method: method,
      StatusCode: statusCode
    });

    // Response time
    this.putMetric('APIResponseTime', responseTime, 'Milliseconds', {
      Route: route,
      Method: method
    });

    // Error tracking
    if (statusCode >= 400) {
      this.putMetric('APIErrors', 1, 'Count', {
        Route: route,
        Method: method,
        StatusCode: statusCode
      });
    }

    // Specific endpoint metrics
    if (route === 'estimates') {
      this.putMetric('EstimateRequestCount', 1, 'Count');
      this.putMetric('EstimateResponseTime', responseTime, 'Milliseconds');
      
      if (statusCode >= 200 && statusCode < 300) {
        this.putMetric('EstimatesGenerated', 1, 'Count');
      }
    }

    if (route === 'analysis') {
      this.putMetric('AnalysisRequestCount', 1, 'Count');
      this.putMetric('AnalysisResponseTime', responseTime, 'Milliseconds');
    }
  }

  /**
   * Record ML service metrics
   */
  recordMLMetrics(operation, latency, success = true, metadata = {}) {
    this.putMetric(`ML${operation}Latency`, latency, 'Milliseconds');
    
    if (!success) {
      this.putMetric(`ML${operation}Errors`, 1, 'Count');
    }

    // Gemini-specific metrics
    if (operation === 'GeminiAPI') {
      this.putMetric('GeminiAPILatency', latency, 'Milliseconds');
      
      if (!success) {
        this.putMetric('GeminiAPIErrors', 1, 'Count');
      }

      if (metadata.framesProcessed) {
        this.putMetric('FramesProcessed', metadata.framesProcessed, 'Count');
      }
    }
  }

  /**
   * Record business metrics
   */
  recordBusinessMetrics(metric, value, dimensions = {}) {
    this.putMetric(metric, value, 'Count', {
      ...dimensions,
      BusinessMetric: 'true'
    });
  }

  /**
   * Record database metrics
   */
  recordDatabaseMetrics(operation, latency, success = true) {
    this.putMetric(`Database${operation}Latency`, latency, 'Milliseconds');
    
    if (!success) {
      this.putMetric(`Database${operation}Errors`, 1, 'Count');
    }
  }

  /**
   * Extract route name from request path
   */
  getRouteFromPath(path) {
    if (path.startsWith('/api/v1/estimates')) return 'estimates';
    if (path.startsWith('/api/v1/analysis')) return 'analysis';
    if (path.startsWith('/health')) return 'health';
    return 'other';
  }

  /**
   * Flush metrics buffer to CloudWatch or log locally
   */
  async flushMetrics() {
    if (this.metricsBuffer.length === 0) return;

    const metrics = [...this.metricsBuffer];
    this.metricsBuffer = [];

    if (cloudWatch) {
      try {
        const params = {
          Namespace: this.namespace,
          MetricData: metrics
        };

        await cloudWatch.putMetricData(params).promise();
        console.log(`✅ Flushed ${metrics.length} metrics to CloudWatch`);
      } catch (error) {
        console.error('❌ Failed to flush metrics to CloudWatch:', error);
        
        // Re-add metrics to buffer for retry (with limit to prevent memory issues)
        if (this.metricsBuffer.length < this.bufferSize * 2) {
          this.metricsBuffer.unshift(...metrics);
        }
      }
    } else {
      // Log metrics locally if CloudWatch is not available
      console.log(`📊 Local metrics (${metrics.length}):`, {
        timestamp: new Date().toISOString(),
        count: metrics.length,
        sample: metrics.slice(0, 3) // Show first 3 metrics as sample
      });
    }
  }

  /**
   * Start periodic metric flushing
   */
  startPeriodicFlush() {
    setInterval(() => {
      this.flushMetrics();
    }, this.flushInterval);

    // Flush on process exit
    process.on('SIGTERM', () => {
      this.flushMetrics();
    });

    process.on('SIGINT', () => {
      this.flushMetrics();
    });
  }

  /**
   * Get current system metrics
   */
  getSystemMetrics() {
    const memoryUsage = process.memoryUsage();
    const uptime = process.uptime();

    return {
      memoryUsage: {
        rss: memoryUsage.rss,
        heapUsed: memoryUsage.heapUsed,
        heapTotal: memoryUsage.heapTotal,
        external: memoryUsage.external
      },
      uptime,
      pid: process.pid,
      nodeVersion: process.version
    };
  }

  /**
   * Record system metrics periodically
   */
  startSystemMetricsCollection() {
    if (!this.enabled) return;

    setInterval(() => {
      const metrics = this.getSystemMetrics();
      
      this.putMetric('MemoryUsageRSS', metrics.memoryUsage.rss, 'Bytes');
      this.putMetric('MemoryUsageHeap', metrics.memoryUsage.heapUsed, 'Bytes');
      this.putMetric('ProcessUptime', metrics.uptime, 'Seconds');
    }, 300000); // Every 5 minutes
  }
}

// Create singleton instance
const metricsService = new MetricsService();

/**
 * Express middleware for automatic API metrics collection
 */
const metricsMiddleware = (req, res, next) => {
  const startTime = Date.now();

  // Override res.end to capture response time
  const originalEnd = res.end;
  res.end = function(...args) {
    const responseTime = Date.now() - startTime;
    metricsService.recordAPIMetrics(req, res, responseTime);
    originalEnd.apply(this, args);
  };

  next();
};

/**
 * Health check endpoint with metrics
 */
const healthCheck = (req, res) => {
  const systemMetrics = metricsService.getSystemMetrics();
  
  const health = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: systemMetrics.uptime,
    memory: systemMetrics.memoryUsage,
    environment: process.env.NODE_ENV,
    version: process.env.APP_VERSION || '1.0.0'
  };

  metricsService.putMetric('HealthCheck', 1, 'Count');
  
  res.json(health);
};

// Start system metrics collection
metricsService.startSystemMetricsCollection();

module.exports = {
  metricsService,
  metricsMiddleware,
  healthCheck
};