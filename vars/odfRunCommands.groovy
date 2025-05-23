def call(String stagee){
    script {
        ansiColor('xterm') {
            echo ""
        }
        try {
            env.STAGE=stagee
            sh '''
               echo "========================  ODF ENV CAPTURED AT STAGE: ${STAGE} ========================" >> ${WORKSPACE}/odf-commands.txt
               sh ${WORKSPACE}/scripts/odf/odf-build-info.sh >> ${WORKSPACE}/odf-commands.txt
               grep "full_version" ${WORKSPACE}/odf-commands.txt | tail -1| awk '{print $2}' > odfbuild
               sh ${WORKSPACE}/scripts/odf/check_crc.sh | tee -a ${WORKSPACE}/check_crc.txt
            '''
             odfbuild = readFile 'odfbuild'
             env.ODF_BUILD = "${odfbuild}".trim()
        }
        catch (err) {
            echo 'Error ! capturing command o/p failed!'
            env.FAILED_STAGE=env.STAGE_NAME
            throw err
        }
    }
}
