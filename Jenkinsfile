node{
    stage('SCM CheckOut'){
        git 'https://github.com/venkatesh3339/vprofile.git'
    }
    stage('Maven-Build'){
        def mvnHome = tool name: 'maven3', type: 'maven'
        sh "${mvnHome}/bin/mvn package"
    }
    stage('Deply-to-tomcat'){
        sshagent(['tomcat-dev']) {
        sh 'scp -o StrictHostKeyChecking=no target/*.war ec2-user@172.31.22.170:/opt/apache-tomcat-8.5.31/webapps'
    }
}
