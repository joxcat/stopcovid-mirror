/**  
* Ce job déclenche l'analyse Sonar à chaque push
**/
pipeline {
    agent any
 stages {
        stage("Trigger manual-sonar job") {
            steps {
                echo "Triggering job for branch ${env.GIT_BRANCH}"
                build job: 'manual-sonar', parameters: [string(name: 'branch', value: "${env.GIT_BRANCH}")], wait: false
            }
        }
    }
}
