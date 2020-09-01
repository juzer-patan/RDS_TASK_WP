provider "aws" {
  region  = "ap-south-1"
  profile = "juzer"

}
provider "kubernetes" {
  config_context_cluster   = "minikube"
}

resource "aws_security_group" "sql_sg" {
  name        = "mysql_db_sg"
  description = "Allow MYSQL inbound traffic"
  vpc_id      = "vpc-5de8f535"

  ingress {
    description = "Allow MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
}



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_mysql"
  }
}
resource "aws_db_instance" "mysql" {
  
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7.30"
  instance_class       = "db.t2.micro"
  name                 = "mysql_wordpress"
  username             = "admin"
  password             = "juzer7894"
  parameter_group_name = "default.mysql5.7"
  publicly_accessible = "true"
  port                = "3306"
  vpc_security_group_ids= ["${aws_security_group.sql_sg.id}",]
  final_snapshot_identifier = "false"
  skip_final_snapshot = "true"
} 

resource "kubernetes_deployment" "WordPress_deploy" {
    depends_on = [aws_db_instance.mysql]
  metadata {
    name = "wp"
    
  }

spec {
    replicas = 1

    selector {
      match_labels = {
        app = "wordpress"
      }
    }

    template {
      metadata {
          name = "wp-pod"
          labels = {
             app = "wordpress"
            }
       }

      spec {
        container {
          image = "wordpress:4.8-apache"
          name  = "wp-cloud"
         
         
        }
      
    }
}
}

}

output "my_op"{
	value =  kubernetes_deployment.WordPress_deploy
}

resource "kubernetes_service" "service" {
    depends_on = [kubernetes_deployment.WordPress_deploy]
  metadata {
    name = "wp-service"
  }
    spec {
    selector = {
      app = "wordpress"
    }
    
    port {
      port        = 8080
      target_port = 80
    }

    type = "NodePort"
    }  
}
