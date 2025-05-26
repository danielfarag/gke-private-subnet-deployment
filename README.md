# gke-private-subnet-deployment

This project helps you deploy a super secure setup on Google Cloud (GCP) using Terraform. It creates a private Google Kubernetes Engine (GKE) cluster that can't directly talk to the internet, and a separate management area to control it. We'll also set up a public website on this private cluster\!

### What You'll Get:

  * **Private GKE:** Your GKE cluster's servers (nodes) and control center are completely isolated from the internet.
  * **Safe Management:** A special "management" area to safely connect to your private GKE cluster.
  * **Public Website:** Your application on GKE will be available to the world through a Google Load Balancer.
  * **Code From Private Registry:** All your application code will come from a secure, private storage.
  * **Everything by Code:** We use Terraform to build all this Google Cloud stuff automatically.

### Website
![alt text](<images/Screenshot from 2025-05-26 23-41-28.png>)


### What You Need (Prerequisites)

Just a few things installed on your computer:

  * **Terraform:** For building the Google Cloud setup.
  * **Docker:** To package your application into a container.
  * **Google Cloud SDK (gcloud CLI):** To talk to Google Cloud from your computer.

And you'll need:

  * Access to a Google Cloud Project with billing enabled.
  * The demo application code: `https://github.com/ahmedzak7/GCP-2025/tree/main/DevOps-Challenge-Demo-Code-master` (for testing).

-----

### Let's Get Started (Deployment Steps)

#### 1\. Prepare Your Google Cloud Project

1.  **Get this project:**
    ```bash
    git clone https://github.com/danielfarag/gke-private-subnet-deployment.git
    cd gke-private-subnet-deployment
    ```
2.  **Tell Google Cloud your project ID:**
    Replace `<YOUR_PROJECT_ID>` with your actual Google Cloud Project ID.
    ```bash
    gcloud config set project <YOUR_PROJECT_ID>
    ```
3.  **Turn on necessary Google Cloud services:**
    ```bash
    gcloud services enable \
        compute.googleapis.com \
        container.googleapis.com \
        artifactregistry.googleapis.com \
        cloudbuild.googleapis.com \
        logging.googleapis.com \
        monitoring.googleapis.com \
        servicenetworking.googleapis.com
    ```

#### 2\. Get Your App Ready (Docker & Private Storage)

1.  **Get the demo app code:**
    ```bash
    git clone https://github.com/ahmedzak7/GCP-2025.git
    cd GCP-2025/DevOps-Challenge-Demo-Code-master
    ```
2.  **Build the app into a Docker image:**
    Replace `<YOUR_GCP_REGION>` (e.g., `us-east1`) and `<YOUR_PROJECT_ID>`. Note that the image name `us-east1-docker.pkg.dev/iti-gcp-course/iti/project:latest` is used here.
    ```bash
    docker build -t us-east1-docker.pkg.dev/iti-gcp-course/iti/project:latest .
    ```
3.  **Log Docker into Google's private storage:**
    ```bash
    gcloud auth configure-docker us-east1-docker.pkg.dev
    ```
4.  **Push your app image to Google's private storage:**
    ```bash
    docker push us-east1-docker.pkg.dev/iti-gcp-course/iti/project:latest
    ```
    *Important: When we deploy the app later, we'll tell it to use this exact path for the image.*

#### 3\. Build Google Cloud Stuff with Terraform

1.  **Go back to this project's folder:**
    ```bash
    cd ../../gke-private-subnet-deployment
    ```
2.  **Terraform setup:**
    ```bash
    terraform init
    ```
3.  **See what Terraform will build (optional, but good to check):**
    ```bash
    terraform plan
    ```
4.  **Make it happen\! (This will take a while, maybe 20-30 mins):**
    ```bash
    terraform apply
    ```
    Type `yes` when it asks.

#### 4\. Deploy Your App to GKE

You can either do this manually or let Terraform handle it.

##### Option A: Manual (using `kubectl`)

1.  **Connect to your Management VM:**
    Once `terraform apply` finishes, it will print the VM's name. Use `gcloud` to connect.

    ```bash
    # On your local computer:
    gcloud compute ssh <your-management-vm-name> --zone=<your-gcp-zone>
    ```

    Inside the VM, get GKE access:

    ```bash
    # Inside the management VM:
    gcloud container clusters get-credentials <gke-cluster-name> --region <your-gcp-region> --project <your-project-id>
    ```

2.  **Apply your app's deployment files:**
    Save the following content as `app-deploy.yaml` on your Management VM, then apply it.

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: redis
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: redis
      template:
        metadata:
          labels:
            app: redis
        spec:
          containers:
          - name: redis
            image: redis:7
            ports:
            - containerPort: 6379
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: redis
    spec:
      selector:
        app: redis
      ports:
        - protocol: TCP
          port: 6379
          targetPort: 6379
    ---
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: python-app-config
    data:
      REDIS_HOST: "redis"
      REDIS_PORT: "6379"
      REDIS_DB: "0"
      ENVIRONMENT: "production"
      HOST: "0.0.0.0"
      PORT: "8080"
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: python-app
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: python-app
      template:
        metadata:
          labels:
            app: python-app
        spec:
          containers:
          - name: python-app
            image: us-east1-docker.pkg.dev/iti-gcp-course/iti/project:latest
            ports:
            - containerPort: 8080
            envFrom:
            - configMapRef:
                name: python-app-config
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: python-app
    spec:
      selector:
        app: python-app
      ports:
        - protocol: TCP
          port: 80
          targetPort: 8080
      type: LoadBalancer
    ```

    Then apply it:

    ```bash
    kubectl apply -f app-deploy.yaml
    ```

##### Option B: Using Terraform (more advanced)

You can add Kubernetes deployment code directly into your Terraform files. If you're new, Option A is probably easier to start with. If you want to try, look at the `kubernetes.tf` file (if provided) or search for `kubernetes_deployment` and `kubernetes_service` resources in Terraform documentation.

-----

### Clean Up (Important\!)

Don't forget to delete everything to avoid extra charges\!

1.  **Destroy all Google Cloud resources:**
    ```bash
    terraform destroy
    ```
    Type `yes` when it asks.

-----

### Credits

This project uses example application code from:

**Ahmed Zakaria**

  * LinkedIn: [https://www.linkedin.com/in/ahmed-zakaria-20184a146/](https://www.linkedin.com/in/ahmed-zakaria-20184a146/)
  * GitHub Demo Code: [https://github.com/ahmedzak7/GCP-2025/tree/main/DevOps-Challenge-Demo-Code-master](https://www.google.com/url?sa=E&source=gmail&q=https://github.com/ahmedzak7/GCP-2025/tree/main/DevOps-Challenge-Demo-Code-master)