module "networking" {
  source = "./modules/networking"
  vpc_cidr = var.vpc_cidr
  public_subnetA_cidr = var.public_subnetA_cidr
  public_subnetB_cidr = var.public_subnetB_cidr
  private_subnetA_cidr = var.private_subnetA_cidr
  private_subnetB_cidr = var.private_subnetB_cidr
}

module "s3" {
  source = "./modules/s3"
}

module "iam" {
  source = "./modules/iam"
  codepipeline_bucket = module.s3.cicd_bucket
  codestar_connection_arn = module.cicd.codestar_connection_arn
}

module "eb" {
  source = "./modules/beanstalk"
  vpc_id = module.networking.vpc_id
  private_sn_ids = module.networking.private_subnet_ids
  alb_sg_id = module.networking.alb_security_group_id
  instance_sg_id = module.networking.instance_security_group_id
  eb_service_role_arn = module.iam.eb_service_role_arn
  public_sn_ids = module.networking.public_subnet_ids
  ec2_instance_profile = module.iam.ec2_instance_profile_arn
}

module "cicd" {
  source = "./modules/cicd"
  eb_app_name = module.eb.eb_app_name
  eb_env_name = module.eb.eb_env_name
  codepipeline_bucket = module.s3.cicd_bucket
  codebuild_role_arn = module.iam.codebuild_role_arn
  codepipeline_role_arn = module.iam.codepipeline_role_arn
  
}