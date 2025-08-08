variable "Project_ID" {
  description = "This is the Project ID"
  type        = string
  default     = "e7e6e9cb-2217-4776-bb94-7d9ac149547d"
}

variable "Project_name" {
  description = "This is the Project ID"
  type        = string
  default     = "default"
}


variable "Model_ID" {
  description = "This is the Device Model ID"
  type        = string
  default     = "8c4b7295-52de-43d8-84c5-934c01ca8305"
}

variable "Docker_runtime_App_Template" {
  description = "This is the Docker Runtime App Template Name"
  type        = string
  default     = "ss_zed-compose-runtime_medium_automation"
} 


variable "docker_compose_app_image" {
  description = "This is the Docker Compose App Image Name"
  type = object({
    name = string
    datastore = string
    artifacts = string
    sha256 = string
    image_size_bytes = string
  })
   default = {
    name = "ss_nginx-nodejs-redis-v01"
    datastore = "sergio_local_ds"
    artifacts = "/nginx-nodejs-redis-docker-compose.tar.gz"
    sha256 = "3566a9d6794a4fd6d01f3fb825fb97f0d8369500d999d3586ab0420b7a108b46"
    image_size_bytes = "6945" 
  }
}

variable "docker_rutime_app_instance_list" {
  type        = list(object({
    runtime_template_name = string
    device_name = string
    switch_device_interface = string
  }))
  default     = [
    {
      runtime_template_name = "ss_zed-compose-runtime_medium_automation"
      device_name = "ss_diconium_docker_device"
      switch_device_interface = "eth0"
    }
  ]
}


variable "docker_compose_app_instance_list" {
  type        = list(object({
    name = string
    app_image_name = string
    category = string
    device_name = string
    artifacts = string
    datastore = string
  }))
  default     = [{
      name = "ss_nginx_nodejs_redis"
      app_image_name = "ss_nginx-nodejs-redis-v01"
      category = "docker-compose"
      device_name = "ss_diconium_docker_device"
      artifacts = "/nginx-nodejs-redis-docker-compose.tar.gz"
      datastore = "sergio_local_ds"
    }
  ]

}




