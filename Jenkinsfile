node{
    stage('SCM CheckOut'){
        git 'https://github.com/venkatesh3339/vprofile.git'
    }
    stage('Maven-Build'){
        def mvnHome = tool name: 'maven3', type: 'maven'
        sh "${mvnHome}/bin/mvn package"
    }
}
