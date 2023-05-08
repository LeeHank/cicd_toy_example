# cicd practice

## 00. 基本設定  



## 01~07 基本的 .gitlab-ci.yml  

* 講了幾個重點：  
  * 用 `stages` 來建立順序，例如 build -> test -> deploy：  
    ```yml
    stages: 
        - build
        - test
        - deploy
    ```
  * 


## 08. 環境變數  

* 直接看官網文件非常詳細： https://docs.gitlab.com/ee/ci/variables/ , 這邊節錄一下官網的重點項目：  
  * local variable: 寫在 .gitlab-ci.yml 的 job 內，只有在這個 job 下才能用  
  * global variable: 寫在 .gitlab-ci.yml 的最外層, 所有 job 都能用    
  * environment variable  
    * default variable: gitlab 事先定義好的 environment variable, 常用的包括：  
      *   
    * user-defined variable (去 settings/cicd/variable 裡面設)  
      * project-level: 同一個 project 下的都可以用 (要是 project member + maintainer 以上才能設)
      * group-level: 同一個 group 下的都可以用 (要是 group member + maintainer 以上才能設)
      * instance-level: 在自己架的 gitlab 中的所有 group & project 都可以用 (只有 admin 才能設) 
  * security: 設置 user-defined variable 時，可以勾選以下選項    
    * mask variable: 如果勾選，那這個變數的值會在 log 裡面被隱藏 (i.e. 就算你在 `.gitlab-ci.yml` 裡面，有去 echo 這個自定義變數，他也不會在 log 鍾顯示出來)      
    * protect variable: 只把此自定義變數，export 到 protected branches (e.g. master) 或 protected tags  

* 底下節錄一下重點
* local variable: 寫在 `.gitlab-ci.yml` 的 job 裡面，只有這個 job 的 scope 可以用此變數。例如下例的 `my_name` 只有在 job1 裡面可以調用  
    ```yml
    stages:
        - build
        - test
        - deploy

    job1:
    variables:
        my_name: "hahahahaha"
    stage: build
    script:
        - echo "Hello! my name is $my_name"
    ```

* global variable: 寫在 `.gitlab-ci.yml` 的最外層，整份文件都可以用此變數。例如下例
    ```yml
    stages:
    - build
    - test
    - deploy

    variables:
        my_name: "hahahahaha"

    job1:
    stage: build
    script:
        - echo "This is job1. Hello! my name is $my_name"
    
    job2:
    stage: build
    script:
        - echo "This is job2. Hello! my name is $my_name"
    ```

* environment variable: 
  * predefined variables：  
    * 可以來這裡查 https://docs.gitlab.com/ee/ci/variables/predefined_variables.html   
    * 常見的：  
        * `CI_COMMIT_BRANCH`: 可以 show 出目前 gitlab-runner 是受到哪個 branch 的 commit 所 trigger。在 .gitlab-ci.yml 檔中，直接用 `$CI_COMMIT_BRANCH` 就可以調用了。例如這個例子：  
            ```yml
            stages:
                - build
                - test
                - deploy

            # 只有發生在 dev 這個分支上的 commit, 我才要動，不然都不動
            workflow:
            rules:
                - if: $CI_COMMIT_BRANCH == "dev"
                when: always
                - when: never
            ```
        * `CI_PIPELINE_SOURCE`: 可以 show 出，目前這個 pipeline 是受到什麼東西 trigger。可能的值包括： `push`, `schedule`, `api`, `merge_request_event`。例如，我想指定當發生 merge request 時，我要 trigger 這個 pipeline，那就這樣寫：
            ```yml
            stages:
                - build
                - test
                - deploy

            # 當發生 merge request 時，我才要動，不然都不動
            workflow:
            rules:
                - if: $CI_PIPELINE_SOURCE == "merge_request_event"
                when: always
                - when: never
            ```
  * 自訂的： 


## 09. Gitlab CI 與 Docker Image  

* 在 `.gitlab-ci.yml` 中，可以像這樣來指定 image   
    ```yml
    stages:
        - build
        - test
        - deploy

    image: image_name:version
    ```

## 10~14. Runner 與 Executor  

* 整體的關係大概是這樣：  
    * gitlab: .gitlab-ci.yml 裡面記錄了一堆待辦事項  
    * runner: 經紀人(派工的)，會去接單，然後發包給 executor    
    * executor: 打工仔 (做工的)，把工單做完，再回報給 runner
* 通常， runner 就是一台灌好gitlab-runner package 的主機(可以下 gitlab-runner 指令)，所以他可以是：  
  * 一台 linux 實體機，然後依照官網文件，安裝好 gitlab-runner package  
  * 一個 container，裡面就是跑一個 image (ubuntu os + gitlab-runner package installed)，所以這個 container 就是個小主機  
* 然後，容易讓人搞混的地方在這了
  * runner到目前為止的解釋方式，就像是 OOP 裡面的一個 class，只是個概念，指的是 "一台安裝好 gitlab-runner package 的 主機", 所以，我更傾向用 `runner server` 來稱呼他。    
  * 但實際在 CI/CD 中運作的 runner，他不是 class，而是 instance。而實例化的方式，在 gitlab 中叫做 register  
  * 我們會在目前這個灌好 gitlab-runner package 的主機上，下 `gitlab-runner register` 指令，然後他會要你填以下關鍵訊息：  
    * gitlab url 是多少？ -> 用官方的，就是 http://gitlab.com, 像公司裡面用自己架的，就把 ip 放這  
    * registraion token 是啥？ -> 在 project 的 ci/cd setting 頁面，會有 token 給你，那註冊下去，就知道這個實例化的 runner 可接受這個專案調用 (但還沒有確定要調用他，要去 .gitlab-ci.yml 做設定，現在只是說可以讓你調用而已)  
    * 給這個 runner 一些 tag? -> 其實就是幫這個 runner 取名字，但是是用貼 tag 的方式。之後在 `.gitlab-ci.yml` 中，就可以用 tag 的方式，來指定我要用這個 runner  
    * 這個 runner 要使用哪種 executor? -> 這是最重要的，這個 runner 可以使喚的工人是哪種類型？ 最常見的是 `shell` 和 `docker`。
      * 如果選 `shell`，那這個 runner 在執行任務時，就是在當前 runner 所在的主機環境上跑。
      * 如果選 `docker`，那他就會進一不叫你提供 image ，那這個 runner 在執行任務時，就是起一個 container 放這個 image，來跑你的任務。附帶一提，其實他這邊叫你提供的 image, 是 default 用，user 仍然可以在 .gitlab-ci.yml 中指定 image, 如果沒指定，那才會用這個 image 來跑  
      * 這邊注意嘿，如果你原本的 runner server 就有 docker 了，那這邊就可以選 docker，他就會起一個 container 來跑  
      * 阿如果你的 runner server 本身其實是個 container，那如果這邊再選 docker，那就變成 docker in docker  
  * 填完這堆訊息後，一個實例化後的 runner 就被建起來了。這個 runner 他的名字是你剛剛貼給他的 tag, 然後他可以被 token 所在的 project 給調用，然後他在執行任務時，會用剛剛指定好的 executor 來執行任務。  
* 到這邊為止，應該對 runner 蠻了解了。之後我會想用 `runner-server`來稱呼 class level 的 runner, 然後用 `runner` 來稱呼實例化後的 runner。所以直白來說， runner 是 runners，因為會有一堆 runner 可以來接工作。  
* 接下來，我們先回顧一下，之前在 gitlab.com 的 project 中，跑的 ci/cd job，點進去看 log，前兩行顯示：  
    ```txt
    Running with `gitlab-runner 15.4.0~beta.5.gdefc7017 (defc7017)  
    Preparing the "docker+machine" executor
    ```
* 這就是在說，當我在 gitlab.com 跑 cicd 時，他給我用 id 為 defc7017 這個 runner (他是 share runner)，然後這個 runner 指派 "docker+machine" 這個 executor 去做事
* 那，我也可以指定自己的 runner  


* 我們來看一下 .gitlab-ci.yml 可以寫成這樣：  

```yml
job1:
    tags:
        - iqm_docker_runner
    stage: testing
    script:
        - echo "unit testing"  
```

## 15. ci/cd 打包 image  

```yml
stages:
    - testing
    - build

run-tests:
    stage: testing
    image: python:3.7.7-slim
    script:
        - pytest

build-docker-image:
    stage: build
    tags:
        - digital_osean_shell
    needs:
        - run-tests
    script:
        - usermod -aG docker gitlab-runner
        - docker build -t registry.gitlab.com/hyleezu/iqm_api:0.1.0 .

push-to-registry:
    stage: publish
    tags:
        - digital_osean_shell
    needs:
        - build-docker-image
    before_script:
        - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD registry.gitlab.com
    script:
        - docker push registry.gitlab.com/hyleezu/iqm_api:0.1.0
```
    
