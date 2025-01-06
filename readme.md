
This guide demonstrates how to deploy a containerized Streamlit web app or any other web application on Snowpark Container Services (SPCS). The process includes setting up Snowflake resources, preparing the application, and configuring SPCS to run your app.

#### Prerequisites

1. **Snowflake Account** with appropriate privileges.
2. **Docker Installed** locally.
3. **Snowflake CLI (snowcli)** for managing Snowflake resources.
4. **Streamlit or your web application** containerized and ready to deploy.

---

#### Steps Overview

1. **Setup Snowflake Objects and Roles**
2. **Install Snowflake CLI**
3. **Retrieve Registry URL of the Image Repository**
4. **Authenticate Docker Using Snowflake CLI**
5. **Push Image to Snowflake Image Repository**
6. **Create Service**
7. **Grant Access to Other Users or Roles**

#### 1. Setup Snowflake Objects and Roles

The following SQL commands set up the necessary Snowflake resources, including a database, schema, image repository, compute pool, and a role with minimal privileges. These resources are required for deploying and managing services in Snowpark Container Services (SPCS).

You can use different names for the objects (`compute_pool_1`, `container_db`, `container_schema`, `con_repo`, `spcs_role`) if desired.
```sql
-- Switch to AccountAdmin role to ensure you have the required permissions
USE ROLE ACCOUNTADMIN;

-- Step 1: Create a new database and schema to organize the container resources
CREATE DATABASE container_db; -- Replace 'container_db' with your preferred database name
CREATE SCHEMA container_schema; -- Replace 'container_schema' with your preferred schema name

-- Step 2: Create a role to manage SPCS-related permissions
CREATE ROLE spcs_role; -- Replace 'spcs_role' with your preferred role name

-- Switch the context to the newly created database and schema
USE DATABASE container_db;
USE SCHEMA container_schema;

-- Step 3: Create an image repository to store container images
CREATE IMAGE REPOSITORY con_repo; -- Replace 'con_repo' with your preferred repository name

-- View the created image repositories and note the URL for use later
SHOW IMAGE REPOSITORIES;

-- Step 4: Create a compute pool to run your containers
-- The compute pool acts like a warehouse and defines the compute resources
CREATE COMPUTE POOL compute_pool_1
  MIN_NODES = 1                    -- Minimum number of nodes to run
  MAX_NODES = 1                    -- Maximum number of nodes to scale to
  INSTANCE_FAMILY = CPU_X64_XS     -- Instance size; adjust based on your workload
  AUTO_RESUME = TRUE               -- Automatically resume the compute pool when needed
  AUTO_SUSPEND_SECS = 120;         -- Automatically suspend after 120 seconds of inactivity

-- Verify the compute pool configuration
DESCRIBE COMPUTE POOL compute_pool_1;

-- Step 5: Grant required permissions to the role
-- Allow the role to bind service endpoints (for creating services)
GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE spcs_role;

-- Grant usage and monitoring privileges on the compute pool
GRANT USAGE, MONITOR ON COMPUTE POOL compute_pool_1 TO ROLE spcs_role;

-- Grant usage and management privileges on the database and schema
GRANT USAGE ON DATABASE container_db TO ROLE spcs_role;
GRANT ALL ON SCHEMA container_schema TO ROLE spcs_role;

-- Grant read and write permissions on the image repository
GRANT READ, WRITE ON IMAGE REPOSITORY con_repo TO ROLE spcs_role;

-- Step 6: Assign the role to necessary users or roles
GRANT ROLE spcs_role TO ROLE ACCOUNTADMIN; -- Assign to AccountAdmin
GRANT ROLE spcs_role TO ROLE DEVELOPER;   -- Assign to Developer role or other users as required
```

#### 2. Install Snowflake CLI
The Snowflake CLI (`snow`) is a specialized tool for managing Snowpark Container Services (SPCS), distinct from SnowSQL.
**Installation**
1. Download the `.deb` package from the [official guide](https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation#label-snowcli-install-linux-package-managers).
2. Install and verify the CLI:
    
    ```bash
    sudo dpkg -i snowflake-cli-<version>.deb
    snow --version
    ```
    

Replace `<version>` with the downloaded version (e.g., `3.2.2`). Ensure administrative privileges for installation.

#### 3. Retrieve Registry URL of the Image Repository

To proceed with pushing your Docker image, you need the **registry URL** and **registry hostname** of the image repository created earlier.
1. Run the following command to list the image repositories:
    
    ```sql
    SHOW IMAGE REPOSITORIES;
    ```
    
2. Locate the repository's URL from the results. The URL typically looks like:
    
    ```
    <orgname>-<acctname>.registry.snowflakecomputing.com/<image_repo_db>/<image_repo_schema>/<image_repo_name>
    ```
    
3. Extract the following details:
    
    - **Registry URL**: The full URL of your image repository.
    - **Registry Hostname**: `<acctname>.registry.snowflakecomputing.com`.

#### 4. Authenticate Docker Using Snowflake CLI

Authentication depends on your Snowflake account setup. There are two scenarios:
##### Scenario 1: **Using Username and Password Without MFA**

If your Snowflake account allows a username and password without MFA, you can authenticate Docker directly without using `snowcli`:

```bash
# Login to the image repository
docker login <registry_hostname> -u <username>
```

This method works for basic accounts but is generally not feasible for enterprise setups where MFA is required.
##### Scenario 2: **Using Snowflake CLI for Enterprise Accounts**
For enterprise accounts with MFA or other security protocols, use `snowcli` to authenticate Docker.

1. **Add a Snowflake Connection**  
    Configure a connection with the necessary details:
    
    ```bash
    # Add a Snowflake connection
    snow connection add
    
    # Populate fields like:
    # account, user, password, role, warehouse (for user/pass authentication)
    # OR
    # account, user, role, warehouse, pk_file, pk_passphrase (for key-pair authentication)
    
    # Leave other fields empty (database, schema, host, port, etc.)
    ```
    
2. **Verify and Set Default Connection**  
    After adding the connection, verify and set it as the default:
    
    ```bash
    # List connections to confirm the addition
    snow connection list
    
    # Set the desired connection as default
    snow connection set-default <connection_name>
    ```
3. **Create a Token and Authenticate Docker Using the Connection**
	After setting up the Snowflake connection, authenticate Docker securely using a token generated by `snowcli`.
	1. **Generate a Token** Use `snowcli` to create an authentication token:
	    
	    ```bash
	    snow spcs image-registry token
	    ```
	    
	2. **Login to the Image Repository** Pipe the token to Docker for authentication:
	    
	    ```bash
	    snow spcs image-registry token --format=JSON | docker login <registry_hostname> -u 0sessiontoken --password-stdin
	    ```
	    
#### 5. Push Image to Snowflake Image Repository
Follow these steps to push your Docker image to the Snowflake image repository:
```bash
# Build Docker Image
docker build -t streamlit-app:latest .

# Retag Image for Snowflake Image Repository
docker tag streamlit-app:latest <your_registry_url>/container_db/container_schema/con_repo/streamlit-app:latest

# Push Image to Repository
docker push <your_registry_url>/container_db/container_schema/con_repo/streamlit-app:latest
```
After pushing the image, you can verify whether it has been successfully uploaded to the Snowflake image repository.
```
SHOW IMAGES IN IMAGE REPOSITORY <repo_name>;
```



#### 6. Create Service

The following SQL commands create, manage, and monitor a Snowpark Container Service for the Streamlit application:

```sql
-- Switch to the role with required permissions
USE ROLE spcs_role;

-- Create the service with container specifications, environment variables, and public endpoint
CREATE SERVICE streamlit_app_service
  IN COMPUTE POOL compute_pool_1
  FROM SPECIFICATION $$
    spec:
      containers:
      - name: st-con -- Name of the container
        image: /container_db/container_schema/con_repo/streamlit-app:latest -- Image URL
        env:
          APP_ENV: stage -- Application environment
          APP_PORT: 5000 -- Port exposed by the application
      endpoints:
      - name: web -- Name of the public endpoint
        port: 5000 -- Publicly exposed port
        public: true -- Make endpoint accessible publicly
      $$
   MIN_INSTANCES = 1 -- Minimum container instances
   MAX_INSTANCES = 1; -- Maximum container instances

-- Suspend the service temporarily
ALTER SERVICE streamlit_app_service SUSPEND;

-- Resume the service
ALTER SERVICE streamlit_app_service RESUME;

-- List all services to verify creation
SHOW SERVICES;

-- Get detailed information about the specific service
DESCRIBE SERVICE streamlit_app_service;

-- Display running containers within the service
SHOW SERVICE CONTAINERS IN SERVICE streamlit_app_service;

-- List endpoints of the service
SHOW ENDPOINTS IN SERVICE streamlit_app_service;

-- Retrieve logs from the service
SELECT SYSTEM$GET_SERVICE_LOGS('streamlit_app_service', '0', 'st-con', 100);

-- Verify available images in the repository
SHOW IMAGES IN IMAGE REPOSITORY con_repo;

-- Optional cleanup: drop an image from the repository
DROP IMAGE streamlit-app FROM IMAGE REPOSITORY con_repo;
```

#### 7. Grant Access to Other Users or Roles
You can grant access to the Streamlit service in Snowflake using one of the following commands. Each command provides a different way to grant access based on your needs. Only **one command** is required to allow access.

**Options:**

```sql
-- Option 1: Grant all endpoint usage for the service to the target role
GRANT SERVICE ROLE streamlit_app_service!all_endpoints_usage TO ROLE developer;

-- Option 2: Grant usage on the database to the target role
GRANT USAGE ON DATABASE container_db TO ROLE developer;

-- Option 3: Grant usage on the schema to the target role
GRANT USAGE ON SCHEMA container_schema TO ROLE developer;

-- Option 4: Grant the SPCS role (with predefined permissions) to the target role
GRANT ROLE spcs_role TO ROLE developer;
```
- For more details on managing Snowpark Container Services, visit the [official documentation](https://docs.snowflake.com/developer-guide/snowpark-container-services/working-with-services).


#### Useful Links

- [Initial Setup Tutorial](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/tutorials/common-setup#verify-that-you-are-ready-to-continue) – Guide for setting up Snowpark Container Services.
- [Flask App Deployment Tutorial](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/tutorials/tutorial-1#create-a-service) – Step-by-step tutorial for deploying a Flask application.
- [SPCS Pricing Details](https://docs.snowflake.com/en/developer-guide/snowpark-container-services/accounts-orgs-usage-views) – Comprehensive information on Snowpark Container Services pricing.