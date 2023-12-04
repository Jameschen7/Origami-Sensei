data_dir="/home/qiyuc/projects/origami_sensei/data/dog_p_on_g_anno_homog_cropped/train"
expe_name="dog_p_on_g_anno_homog_cropped_train"
GPU="1"

timestr=` date +%m_%d-%H_%M `
expe_name="${expe_name}/${timestr}"
mkdir -p "outputs/${expe_name}"
CUDA_VISIBLE_DEVICES="${GPU}" python3 train.py ${data_dir} ${expe_name} \
    2>&1 | tee "outputs/${expe_name}/log.txt"
