


data "zedcloud_datastore" "my_datastore" {  
  name        = "${var.docker_compose_app_image.datastore}"
  title       = "${var.docker_compose_app_image.datastore}"
  ds_type     = "DATASTORE_TYPE_FILE_STORAGE"
  ds_fqdn = "http://192.168.1.9:8080"

}

data "zedcloud_datastore" "docker_hub_datastore" {  
  name        = "Dockerhub_compose"
  title       = "Dockerhub_compose"
  ds_type     = "DATASTORE_TYPE_Container_Registry"
  ds_fqdn = "docker.io"

}

data "zedcloud_edgenode" "my_node" {
  for_each = { for i in var.docker_rutime_app_instance_list : i.device_name => i }
  name = each.value.device_name
  title = each.value.device_name
  model_id = "e54adc1c-aebb-4013-955b-03db2b573221"

  interfaces {
    intfname = "eth0"
  }
}



/*
Docker Compose Application Image
This resource creates the image for the Docker Compose application
*/
resource "zedcloud_image" "docker_compose_app_image" {
  name                = var.docker_compose_app_image.name
  title               = var.docker_compose_app_image.name
  datastore_id        = data.zedcloud_datastore.my_datastore.id
  image_format        = "RAW"
  image_type          = "IMAGE_TYPE_DOCKER_COMPOSE_TAR"
  image_rel_url       = "${var.docker_compose_app_image.artifacts}"
  image_sha256        = var.docker_compose_app_image.sha256
  image_size_bytes    = var.docker_compose_app_image.image_size_bytes
}


resource "zedcloud_application" "docker_compose_app" {
  name                 = var.docker_compose_app_image.name
  title                =var.docker_compose_app_image.name
  description          = "compose app bundle"
  user_defined_version = "0.1"
  origin_type          = "ORIGIN_LOCAL"
  datastore_id_list = [
    data.zedcloud_datastore.docker_hub_datastore.id
  ]
  manifest {
    ac_kind         = "ComposeManifest"
    ac_version      = "0.1"
    app_type        = "APP_TYPE_DOCKER_COMPOSE"
    deployment_type = "DEPLOYMENT_TYPE_STAND_ALONE"
    name            = var.docker_compose_app_image.name

    owner {
      user    = "Test User"
      email   = "test@zededa.com"
      website = "www.zededa.com"
    }
    desc {
      app_category = "APP_CATEGORY_UNSPECIFIED"
      category = "test"
      logo = {
      }
      license_list = {
        "APACHE_LICENSE_V2": "https://choosealicense.com/licenses/apache-2.0/"
      }
      agreement_list = {
        "AGREEMENT_LIST_KEY": "AGREEMENT_LIST_VALUE"
      }
      screenshot_list = {
        "screenshot_list_key": "screenshot_list_value"
      }
    }
    docker_compose_tar_image_name =  var.docker_compose_app_image.name
  }
  depends_on = [ zedcloud_image.docker_compose_app_image ]
}



resource "zedcloud_network_instance" "switch_netinst_runtime_1" {
  for_each = { for i in var.docker_rutime_app_instance_list : i.device_name => i } 

  device_id =  data.zedcloud_edgenode.my_node[each.key].id

  name = "switch_netinst_${each.value.device_name}_${each.value.switch_device_interface}"
  title = "title"
  kind = "NETWORK_INSTANCE_KIND_SWITCH"
  port = each.value.switch_device_interface

  # optional
  description = "switch_network_inst_eth0"
  mtu = 1500
}

resource "zedcloud_network_instance" "airgapped_netinst_runtime_1" {
  for_each = { for i in var.docker_rutime_app_instance_list : i.device_name => i } 

  device_id =  data.zedcloud_edgenode.my_node[each.key].id

  name = "local_airgapped_${each.value.device_name}"
  title = "title"
  kind = "NETWORK_INSTANCE_KIND_LOCAL"
  port = ""

  # optional
  description = "zedcloud_network_instance-complete-description"
  type = "NETWORK_INSTANCE_DHCP_TYPE_V4"
  device_default = false
  mtu = 1500
  ip {
      domain = ""
      gateway = "10.20.0.1"
      subnet = "10.20.0.0/16"
      dhcp_range {
          start = "10.20.0.100"
          end = "10.20.0.200"
      }
    }


}

data "zedcloud_application" "docker_compose_rt_app" {
  for_each = { for i in var.docker_rutime_app_instance_list : i.device_name => i }

  name = each.value.runtime_template_name
  title = each.value.runtime_template_name
}

resource "zedcloud_application_instance"  "docker_rt_appinstance" {

  for_each = { for i in var.docker_rutime_app_instance_list : i.device_name => i } 


  name        = "zed-docker-runtime-${each.value.device_name}"
  title       = "zed-docker-runtime-${each.value.device_name}"
  description = "test docker runtime app instance"
  app_id      = data.zedcloud_application.docker_compose_rt_app[each.key].id
  app_type    = "APP_TYPE_VM"
  device_id   = data.zedcloud_edgenode.my_node[each.key].id
  interfaces {
    intfname = "eth1-ext"
    intforder = 1
    directattach = false
    access_vlan_id = 0
    default_net_instance = false
    ipaddr = ""
    macaddr = ""
    netinstname  = zedcloud_network_instance.switch_netinst_runtime_1[each.key].name
    privateip = false
  }
  interfaces {
    intfname = "eth2-int"
    intforder = 2
    directattach = false
    access_vlan_id = 0
    default_net_instance = false
    ipaddr = "10.20.0.201"
    macaddr = ""
    netinstname  = zedcloud_network_instance.airgapped_netinst_runtime_1[each.key].name
    privateip = false
  }

  custom_config {
    add             = true
    allow_storage_resize = true
    field_delimiter = "###"
    name            = "cloud-config"
    override        = true
    #template        = base64encode(file("./c-init/pentair_rt.txt"))
    template        = base64encode(file("./ci-scripts/docker-rt-ci.txt"))

  }
  

  logs {
    access = true
  }
  manifest_info {
    transition_action = "INSTANCE_TA_NONE"
  }
  custom_config {
    add = false
    allow_storage_resize = false
    override = false
  }


  depends_on = [ zedcloud_network_instance.airgapped_netinst_runtime_1, 
                 zedcloud_network_instance.switch_netinst_runtime_1
   ]
}


resource "zedcloud_application_instance"  "docker_compose_appinst" {

  for_each = { for i in var.docker_compose_app_instance_list : i.device_name => i }


  depends_on = [
    zedcloud_application_instance.docker_rt_appinstance,
    zedcloud_application.docker_compose_app
  ]

  name        = "${each.value.name}"
  title       = "${each.value.name}"
  description = " "
  app_id      = zedcloud_application.docker_compose_app.id
  app_type    = zedcloud_application.docker_compose_app.manifest[0].app_type
  device_id   = data.zedcloud_edgenode.my_node[each.key].id
  
  logs {
    access = true
  }
  manifest_info {
    transition_action = "INSTANCE_TA_NONE"
  }
  custom_config {
    add = false
    allow_storage_resize = false
    override = false
  }
}
