# ContractorLens

**ContractorLens** is a comprehensive construction cost estimation tool designed to streamline the estimation process for contractors. It leverages Augmented Reality (AR) for room scanning, machine learning for material analysis, and a powerful backend for deterministic cost calculations.

## Features

*   **AR-Powered Room Scanning:** The iOS app uses ARKit and RoomPlan to create 3D models of rooms and capture precise measurements.
*   **AI-Powered Material Analysis:** A dedicated Gemini ML service analyzes images from the AR scans to identify materials, assess their condition, and provide recommendations.
*   **Deterministic Cost Estimation:** The backend features a robust "Assembly Engine" that calculates construction costs based on structured data, ensuring accurate and consistent estimates.
*   **RESTful API:** A secure and scalable RESTful API for managing estimates, materials, and other project data.
*   **Containerized Deployment:** The entire application is containerized using Docker, allowing for easy and consistent deployment across different environments.

## Architecture

The ContractorLens application is built on a microservices architecture, with three main components:

1.  **Backend:** A Node.js/Express application that serves as the core of the system. It handles business logic, data storage, and communication with the other services.
2.  **iOS App:** A native iOS application built with SwiftUI that provides the user interface for room scanning and project management.
3.  **Gemini ML Service:** A Node.js service that integrates with Google's Gemini model to provide AI-powered image analysis capabilities.

These services communicate with each other via a RESTful API, with an Nginx reverse proxy routing requests to the appropriate service.

## Getting Started

### Prerequisites

*   Docker and Docker Compose
*   Node.js and npm
*   Xcode and the iOS SDK
*   An environment file (`.env`) with the necessary credentials for Firebase and Gemini. An example is provided in `.env.example`.

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/mirzaik-wcc/ContractorLens.git
    ```
2.  Create a `.env` file from the example:
    ```bash
    cp .env.example .env
    ```
3.  Add your Firebase and Gemini credentials to the `.env` file.

## Usage

### Running with Docker Compose

To run the entire application, use the following command from the project root:

```bash
docker-compose up -d
```

This will start the following services:

*   `postgres`: The PostgreSQL database.
*   `backend`: The main backend application.
*   `gemini-service`: The Gemini ML service.
*   `nginx`: An Nginx reverse proxy.

### Running Services Individually

#### Backend

To run the backend service individually:

```bash
cd backend
npm install
npm run dev
```

The backend will be available at `http://localhost:3000`.

#### Gemini ML Service

To run the Gemini ML service individually:

```bash
cd ml-services/gemini-service
npm install
npm start
```

The Gemini service will be available at `http://localhost:3001`.

#### iOS App

To run the iOS app, open the `ContractorLens.xcodeproj` file in Xcode and run the app on a simulator or a physical device.

## Testing

#### Backend

To run the backend tests:

```bash
cd backend
node tests/unit.test.js
```

#### Gemini ML Service

To run the Gemini ML service tests:

```bash
cd ml-services/gemini-service
npm test
```

## CI/CD

The project uses GitHub Actions for continuous integration and continuous deployment. The following workflows are defined:

*   `backend-ci-cd.yml`: Builds and tests the backend service.
*   `ios-ci-cd.yml`: Builds and tests the iOS app.
*   `infrastructure-deployment.yml`: Deploys the infrastructure using Terraform.

## Infrastructure

The infrastructure for the ContractorLens application is managed using Terraform. The Terraform configuration files can be found in the `infrastructure/terraform` directory.

## Monitoring

The application is monitored using a combination of Prometheus, Grafana, and CloudWatch. The monitoring configuration files can be found in the `monitoring` directory.

## Database Schema

The database schema is defined in the `database/schemas/schema.sql` file. The database is seeded with initial data from the files in the `database/seeds` directory.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue.

## License

This project is licensed under the MIT License.