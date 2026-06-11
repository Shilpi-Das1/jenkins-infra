def call() {

    if (!env.BASTION_IP?.trim()) {
        echo "ERROR: BASTION_IP is not set — skipping screenshots"
        currentBuild.result = 'UNSTABLE'
        return
    }

    try {
        sh '''
            set -e
            cd ${WORKSPACE}/deploy

            echo "=========================================="
            echo "Fetching console URL and password from bastion"
            echo "=========================================="

            CONSOLE_URL=$(ssh -o StrictHostKeyChecking=no -i id_rsa \
                root@${BASTION_IP} \
                "oc whoami --show-console 2>/dev/null")

            KUBEADMIN_PASSWORD=$(ssh -o StrictHostKeyChecking=no -i id_rsa \
                root@${BASTION_IP} \
                "cat /root/openstack-upi/auth/kubeadmin-password")

            echo "Console URL: ${CONSOLE_URL}"
            echo "${CONSOLE_URL}"        > /tmp/ocp_console_url.txt
            echo "${KUBEADMIN_PASSWORD}" > /tmp/ocp_kubeadmin_password.txt

            echo "=========================================="
            echo "Checking network connectivity to console"
            echo "=========================================="
            HTTP_CODE=$(curl -sk --max-time 15 "${CONSOLE_URL}" \
                -o /dev/null -w "%{http_code}" || echo "000")
            echo "HTTP response code: ${HTTP_CODE}"
            if [ "${HTTP_CODE}" = "000" ]; then
                echo "ERROR: Cannot reach console URL"
                exit 1
            fi
            echo "Console is reachable"

            echo "=========================================="
            echo "Installing Firefox"
            echo "=========================================="
            FIREFOX_BIN=$(which firefox 2>/dev/null || true)
            if [ -z "${FIREFOX_BIN}" ] || [ ! -x "${FIREFOX_BIN}" ]; then
                echo "Downloading Firefox from Mozilla..."
                FIREFOX_URL="https://releases.mozilla.org/pub/firefox/releases/128.0esr/linux-x86_64/en-US/firefox-128.0esr.tar.bz2"
                curl -L --retry 3 --retry-delay 5 \
                    "${FIREFOX_URL}" -o /tmp/firefox.tar.bz2
                tar -xjf /tmp/firefox.tar.bz2 -C /opt/
                ln -sf /opt/firefox/firefox /usr/local/bin/firefox
                rm -f /tmp/firefox.tar.bz2
                echo "Firefox installed: $(/usr/local/bin/firefox --version)"
            else
                echo "Firefox found: $(${FIREFOX_BIN} --version)"
            fi

            echo "=========================================="
            echo "Installing geckodriver"
            echo "=========================================="
            GECKO_BIN=$(which geckodriver 2>/dev/null || true)
            if [ -z "${GECKO_BIN}" ] || [ ! -x "${GECKO_BIN}" ]; then
                echo "Downloading geckodriver..."
                GECKO_VER=$(curl -s \
                    "https://api.github.com/repos/mozilla/geckodriver/releases/latest" \
                    | python3 -c \
                    "import sys,json; print(json.load(sys.stdin)['tag_name'])")
                echo "Latest geckodriver: ${GECKO_VER}"
                curl -sL \
                    "https://github.com/mozilla/geckodriver/releases/download/${GECKO_VER}/geckodriver-${GECKO_VER}-linux64.tar.gz" \
                    | tar -xz -C /usr/local/bin/
                chmod +x /usr/local/bin/geckodriver
                echo "Geckodriver installed: $(geckodriver --version | head -1)"
            else
                echo "Geckodriver found: $(${GECKO_BIN} --version | head -1)"
            fi

            echo "=========================================="
            echo "Installing selenium"
            echo "=========================================="
            VENV_PYTHON="/tmp/screenshot-venv/bin/python3"

            if [ ! -f "${VENV_PYTHON}" ]; then
                echo "Trying to create venv..."
                apt-get install -y python3-venv 2>/dev/null || \
                apt-get install -y python3.11-venv 2>/dev/null || \
                apt-get install -y python3.12-venv 2>/dev/null || true

                if python3 -m venv /tmp/screenshot-venv 2>/dev/null; then
                    echo "Venv created — installing selenium..."
                    /tmp/screenshot-venv/bin/pip install --upgrade pip --quiet
                    /tmp/screenshot-venv/bin/pip install selenium --quiet
                    echo "Selenium: $(${VENV_PYTHON} -c \
                        'import selenium; print(selenium.__version__)')"
                else
                    echo "Venv not available — using --break-system-packages"
                    pip3 install selenium \
                        --break-system-packages --quiet 2>/dev/null || \
                    pip install selenium \
                        --break-system-packages --quiet 2>/dev/null || \
                    python3 -m pip install selenium \
                        --break-system-packages --quiet
                    VENV_PYTHON=$(which python3)
                    echo "Selenium: $(python3 -c \
                        'import selenium; print(selenium.__version__)')"
                fi
            else
                echo "Venv exists — checking selenium..."
                ${VENV_PYTHON} -c \
                    "import selenium; print('selenium', selenium.__version__)" \
                    2>/dev/null || \
                    /tmp/screenshot-venv/bin/pip install selenium --quiet
            fi

            echo "${VENV_PYTHON}" > /tmp/screenshot_python_cmd.txt
            echo "Python cmd: $(cat /tmp/screenshot_python_cmd.txt)"

            echo "=========================================="
            echo "Final dependency check"
            echo "=========================================="
            python3 --version
            /usr/local/bin/firefox --version
            /usr/local/bin/geckodriver --version | head -1
            PYTHON_CMD=$(cat /tmp/screenshot_python_cmd.txt)
            ${PYTHON_CMD} -c \
                "import selenium; print('selenium', selenium.__version__)"
            echo "All dependencies OK"
        '''

        sh '''
            set -e

            CONSOLE_URL=$(cat /tmp/ocp_console_url.txt)
            KUBEADMIN_PASSWORD=$(cat /tmp/ocp_kubeadmin_password.txt)
            PYTHON_CMD=$(cat /tmp/screenshot_python_cmd.txt)

            echo "=========================================="
            echo "Running screenshot collector"
            echo "Console: ${CONSOLE_URL}"
            echo "Python: ${PYTHON_CMD}"
            echo "=========================================="

            mkdir -p ${WORKSPACE}/deploy/ui-screenshots

            CONSOLE_URL="${CONSOLE_URL}" \
            KUBEADMIN_PASSWORD="${KUBEADMIN_PASSWORD}" \
            OUTPUT_DIR="${WORKSPACE}/deploy/ui-screenshots" \
            ${PYTHON_CMD} \
                ${WORKSPACE}/scripts/ocp-console-screenshot.py 2>&1

            echo "=========================================="
            echo "Verifying output"
            echo "=========================================="
            ls -lah ${WORKSPACE}/deploy/ui-screenshots.tar.gz
            tar -tzf ${WORKSPACE}/deploy/ui-screenshots.tar.gz | head -20
            echo "Screenshot stage completed successfully"
        '''

        archiveAllArtifacts("deploy/ui-screenshots.tar.gz")

    } catch(err) {
        echo "Screenshot capture failed — marking UNSTABLE: ${err.toString()}"
        sh '''
            set +e
            cd ${WORKSPACE}/deploy
            cp /tmp/login_failure.png \
                ${WORKSPACE}/deploy/login_failure.png 2>/dev/null || true
            ls -la ${WORKSPACE}/deploy/ui-screenshots.tar.gz 2>/dev/null || true
            exit 0
        '''
        archiveAllArtifacts("deploy/login_failure.png")
        currentBuild.result = 'UNSTABLE'
    }
}