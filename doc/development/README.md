
### Update steps to support a new version of yq

On a develop branch, on the development host machine:

* Install the new version of yq using the `install_yq.sh` script providing the `--yq_version` parameter
* Generate the sha512 checksums for `yq_linux_amd64.tar.gz` and `yq_linux_amd64`

    For example:

    ```
    $ .extras/bin/install_yq.sh --yq_version=v4.40.4
    $  cd ~/.ansible/tmp/downloads/yq/v4.40.4
    $ sha512sum yq_linux_amd64.tar.gz yq_linux_amd64
    2883547123e870da99df86359c50056eb9cfd194b776df4e1953944926d184108e70bb21fe7ceb2969d1d80f129eca3b582a539ff2ec2345e578b8cc1287132f  yq_linux_amd64.tar.gz
    b99383509062f398275294b611dba197814e470d968658da3a28f40caaff7157bfb34d439ffbbd78443ca3c590913604231ae17af6fa270755c52c3d6388dfd9  yq_linux_amd64
    ```
* Record the sha512 checksums in `defaults/main.yml` in `adrianjuhl__yq__yq_archive_file_sha512_checksums` and `adrianjuhl__yq__yq_executable_file_sha512_checksums` respectively
* Update `adrianjuhl__yq__yq_version` to default to the latest version

