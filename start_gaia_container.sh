#!/bin/bash

IMG_NAME='gaia'

ABS_CUR_DIR=$( cd `dirname $BASH_SOURCE`;pwd )
cd $ABS_CUR_DIR

image_name="gaia_images.tar"

gaia_attach_path='/opt/gaia/admingateway'
yunyou_attach_path='/opt/gaia/yunyou'
dockerregistry_attach_path='/opt/gaia/dockerregistry'

function print_log(){
    msg=$1
    type=$2
    if [[ $type"x" == "x" ]];then
        type='info'
    fi

    if [[ $type == "info" ]];then
        # set msg color green which print to screen
        echo -e "\033[32m[`date`] [$type] $msg \033[0m"
    else
        echo -e "\033[31m[`date`] [$type] $msg \033[0m"
    fi
}

function load_gaia_img(){
    print_log "load gaia imgae ..."
    # check if img exist
    is_gaia_img_exist=`docker images | grep acs-reg.alipay.com/acloud/gaia | wc -l`
    is_gaia_img_exist=`echo ${is_gaia_img_exist} | sed 's/^[ \t]//g'`
    if [[ ${is_gaia_img_exist}"x" != "0x" ]];then
        print_log "img gaia already exist, not to load"
    else
        print_log "load gaia img: ${image_name}"
        if [[ $use_pouch ]];then
            docker load -i ${gaia_attach_path}/${image_name} 'acs-reg.alipay.com/acloud/gaia'
        else
            docker load -i ${gaia_attach_path}/${image_name}
        fi
    fi
}

function gaia_init(){
    is_gaia_img_exist=`ls -l | grep ${image_name}`
    if [[ "${is_gaia_img_exist}x" == "x" ]];then
        print_log "./${image_name} not exist!" "error"
        exit 1
    fi
    print_log "gaia init ..."
    # create attach path
    host_path_2_attach='/opt/gaia/admingateway'
    container_path_2_attach='/opt/gaia/admingateway'

    mkdir -p ${host_path_2_attach}
    mkdir -p ${yunyou_attach_path}
    mkdir -p ${dockerregistry_attach_path}

    print_log "conf gaia ..."
    # copy for gaia in the zone
    if [[ $ABS_CUR_DIR != ${host_path_2_attach} ]];then
        cp -f ./${image_name} ${host_path_2_attach}
        cp -f ./start_gaia_container.sh ${host_path_2_attach}
    fi
}

function start_gaia(){
    print_log "start gaia ..."
    # check if gaia already exist
    is_gaia_container_exist=`docker ps | grep gaia | wc -l`
    is_gaia_container_exist=`echo ${is_gaia_container_exist} | sed 's/^[ \t]//g'`
    if [[ ${is_gaia_container_exist}"x" != "0x" ]];then
        print_log "container gaia already exist, not to start again!"
    else
        host_path_2_attach='/opt/gaia/'
        container_path_2_attach='/opt/gaia/'
        if [[ $use_pouch ]];then
            image=`docker images | grep acs-reg.alipay.com/acloud/gaia | awk '{print $2}' | head -n 1`
        else
            image=`docker images | grep acs-reg.alipay.com/acloud/gaia | awk '{print $1":"$2}' | head -n 1`
        fi
        print_log "docker run -d -e TERM=xterm --net host --name gaia -v ${host_path_2_attach}:${container_path_2_attach} ${image}"
        docker run -d -e TERM=xterm --net host --name gaia -v ${host_path_2_attach}:${container_path_2_attach} ${image}
    fi
}

function init_with_gry_tgz(){
    is_gry_img_exist=`ls -l | grep gry_images.tgz`
    if [[ "${is_gry_img_exist}x" == "x" ]];then
        print_log "./gry_images.tgz not exist!" "error"
        exit 1
    fi

    print_log "init with gry_images.tgz ..."
    mkdir -p ${gaia_attach_path}
    mkdir -p ${yunyou_attach_path}
    mkdir -p ${dockerregistry_attach_path}

    # unpack gry images
    print_log "untaring gry_images.tgz ..."
    tar -zxvf ./gry_images.tgz
    print_log "conf gaia, registry, yunyou images  ..."
    mv ./gry_images/yunyou_images.tar ${yunyou_attach_path}
    mv ./gry_images/registry_images.tar ${dockerregistry_attach_path}
    mv ./gry_images/gaia_images.tar ${gaia_attach_path}

    cp -f ./start_gaia_container.sh ${gaia_attach_path}
    print_log 'deal with gry_images done '
}

if [[ $1 == 'gry' ]];then
    init_with_gry_tgz
elif [[ $1 == 'pouch' ]];then
    use_pouch=true
    gaia_init
else
    gaia_init
fi


load_gaia_img
start_gaia

