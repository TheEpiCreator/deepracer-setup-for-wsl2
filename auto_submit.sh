# Code from:
# https://blog.gofynd.com/how-we-broke-into-the-top-1-of-the-aws-deepracer-virtual-circuit-c39a241979f5

#Reload all deepracer commands
source ~/deepracer-for-cloud/bin/activate.sh
while true
do 
    #delete previous model files
    aws s3 rm s3://epcr-subit/Models/model --recursive;
    aws s3 rm s3://epcr-subit/Models/ip --recursive;    #Upload the latest model
    yes | dr-upload-model -fz;    #Move some files to maintain the expected model directory
    aws s3 sync s3://epcr-subit/Models/model/reward_function.py s3://epcr-subit/reward_function.py;
    
    aws s3 sync s3://epcr-subit/Models/model/hyperparameters.json s3://epcr-subit/hyperparameters.json;
    
    aws s3 sync s3://epcr-subit/Models/ip/model_metadata.json s3://epcr-subit/model_metadata.json;
    
    sleep 10m;
done