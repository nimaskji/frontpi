let express = require("express");
let router = express.Router();

let os = require("os");

router.get("/", function(req,res,next){

    /**
     * Get all System Datas
     */
    let Pi = require("../bin/RaspberryFct");

    Pi.getSystemInfo(function(datas){
        res.render("index", {
            page: "system",
            datas: datas,
        });
    });

});

router.get("/aws", function(req,res,next){

    let Pi = require("../bin/RaspberryFct");

    let fs = require("fs");
    fs.exists("credential", function(exists){

        let credential = undefined;
        if(!exists){
            credential = false;
            res.render("aws", {
                    page: "aws",
                    datas: {
                        ec2: null,
                        credential: credential,
                        uptime: os.uptime()
                    },
                });
        }
        else{

            credential = JSON.parse(require('fs').readFileSync('credential', 'utf8'));
            
            // Try to access to AWS with cred
            let aws = require("aws-sdk");
            let ec2 = new aws.EC2({
                region: credential.aws_region,
                credentials: new aws.Credentials(credential.iam_id,credential.iam_secret)
            });

            // help : https://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/EC2.html#runInstances-property
            let paramsEC2 = {
                ImageId:"ami-71d8820b", //--> Debian 9 MarketPlace
                MaxCount:1,
                MinCount:1,
                KeyName:credential.ec2_key,
                SecurityGroupIds: [credential.ec2_sg],
                UserData: require("../bootstrap.encoded.json").datas,
                InstanceType: "t2.micro",
                TagSpecifications: [
                    {
                        ResourceType: "instance",
                        Tags: [{Key: "Name",Value:credential.ec2_tagName}]
                    }
                ]
            }

            ec2.describeInstances({Filters:[{Name: "tag:Name", Values: [credential.ec2_tagName]}]}, function(err,data){

                if(err != null){
                    // found running instance with TAG RASPI-#SERIAL#
                }

                let ec2 = null;
                if(data.Reservations.length === 0){
                    ec2 = null;
                }
                else{
                    //console.log(data.Reservations[0].Instances[0]);
                    ec2 = data.Reservations[0].Instances[0]; 
                    if(ec2.State.Name != "running") ec2 = null;
                }

                res.render("aws", {
                    page: "aws",
                    datas: {
                        error: err,
                        ec2: ec2,
                        credential: credential,
                        uptime: os.uptime()
                    },
                });

            });

        }

    })

});

/**
* Start the instance on AWS EC2
**/
router.get("/aws/start", function(req,res,next){

    // Get cred infos
    credential = JSON.parse(require('fs').readFileSync('credential', 'utf8'));

    // Try to list all instances on the AWS Account
    let aws = require("aws-sdk");
    let ec2 = new aws.EC2({
        region: credential.aws_region,
        credentials: new aws.Credentials(credential.iam_id,credential.iam_secret)
    });

    // List all EC2
    if(ec2.describeInstances({}, function(err,datas){

        // CHeck if we have one instance
        if(datas.Reservations.length >= 1 && credential.ec2_limit_one){
            res.render("aws",{
                page: "aws",
                datas: {
                    error_start: "You can't run when you have more than one instance !",
                    ec2: null,
                    credential: credential,
                    uptime: os.uptime
                }
            });
        }
        else{

            // No soucy to run a new instance
            // help : https://docs.aws.amazon.com/AWSJavaScriptSDK/latest/AWS/EC2.html#runInstances-property
            let paramsEC2 = {
                ImageId:"ami-71d8820b", //--> Debian 9 MarketPlace
                MaxCount:1,
                MinCount:1,
                KeyName:credential.ec2_key,
                SecurityGroupIds: ["sg-c296d6b5"],
                UserData: require("../b64.js").b64, //--> the bootstrap scrip in B64 encoded
                InstanceType: "t2.micro",           //--> Free Tier
                TagSpecifications: [
                    {
                        ResourceType: "instance",
                        Tags: [{Key: "Name",Value:credential.ec2_tagName}]
                    }
                ]
            }

            // Create the intance
            ec2.runInstances(paramsEC2, function(err,data){
                res.render("aws",{
                    page: "aws",
                    datas: {
                        success_start: "EC2 created with success, please wait enf of provisionning",
                        ec2: data.Instances[0],
                        credential: credential,
                        uptime: os.uptime
                    }
                });
            });
        }

    }));


});

/**
* Stop the instance on AWS EC2
**/
router.get("/aws/stop", function(req,res,next){

    // Get cred infos
    credential = JSON.parse(require('fs').readFileSync('credential', 'utf8'));

    // Try to list all instances on the AWS Account
    let aws = require("aws-sdk");
    let ec2 = new aws.EC2({
        region: credential.aws_region,
        credentials: new aws.Credentials(credential.iam_id,credential.iam_secret)
    });

    ec2.describeInstances({Filters:[{Name: "tag:Name", Values: [credential.ec2_tagName]}]}, function(err,datas){

        let ec2_id = datas.Reservations[0].Instances[0].InstanceId;
        ec2.terminateInstances({InstanceIds: [ec2_id]}, function(err,datas){
            console.log(err);
            res.render("aws",{
                page: "aws",
                datas: {
                    success_start: "EC2 deleted with success",
                    ec2: null,
                    credential: credential,
                    uptime: os.uptime
                }
            });
        });

    });

});

/**
* Save IAM credential to use AWS-SDK
**/
router.post("/aws/iam", function(req,res,next){

    let Pi = require("../bin/RaspberryFct");
    let credential = req.body;

    Pi.getSystemInfo(function(piDatas){
        credential.ec2_tagName = piDatas.hardware.Version+"-"+piDatas.hardware.Serial
        let fs = require("fs");
        fs.writeFile("credential", JSON.stringify(req.body));
        res.redirect("/aws");
    });

});

router.get("/services", function(req,res,next){

    let ServiceManager = require("../bin/services/ServiceManager");

    ServiceManager.getAllServiceStatus(function (svcinfo) {
        res.render("services", {
            page: "services",
            datas: {
                uptime: os.uptime(),
                svcinfo: svcinfo
            },
        });
    });

});

router.get("/shares", function(req,res,next){

    res.render("shares", {
        page: "shares",
        datas: {
            uptime: os.uptime()
        }
    });
});

router.get("/reboot", function (req, res, next) {
    let Pi = require("../bin/RaspberryFct");

    res.render("waitpage", {
        page: "reboot",
        datas: {

        },
        uptime: os.uptime()

    });
    Pi.rebootPi();
});

module.exports = router;