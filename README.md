# Docker

### 명령어

| Command  | Descrtion | Option |
| --- | --- | --- | 
| docker run ${IMAGE}          |   |  | 
| docker run ${IMAGE} ${CMD} -a | 명령어 실행  | -a(attach : 내부 내용 보임) | 
| docker run -d -p 80:8080 ${image id/name}  |   | -p(80을 컨터에너 8080으로 매핑)  |
| docker create ${IMAGE}       |   |  |
| docker start ${ID}           |   |  |
| docker exec ${컨테이너 ID} ${CMD}  | 실행중인 컨테이너에 명령어 실행  |  |
| docker exec -it ${컨테이너 ID} ${CMD}  | 실행중인 컨테이너에 명령어 계속 실행, i: 상호 입출력, t: tty를 활성화하여 bash쉘 사용 |  |
| docker exec -it ${컨테이너 ID} sh  | 컨터에너 터미널 실행  | exit or cntl+d로 나옴 |
| docker ps -a |  list  |  |
| docker rm ${id/name}  | delete  |  |
| docker rm \`docker ps -a -q\`  | 전체 삭제  |  |
| docker rmi ${이미지id} |   |  |
| docker system prune  | 한번에 컨터이너, 이미지, 네트워크 삭제. 실행중인 컨테이너는 영향을 주지 않음  |  |
| docker build -t ${docker id}/${name}:latest ./  | name으로 빌드  |  |
| docker build -f Dockerfile.dev ./  | Dev 빌드  |  |
| docker -v $(pwd):/usr/src/app  | 경로 매핑  | $(pwd)를 그대로 입력(path)  |
| docker -v /usr/src/app/node_modules  | 현재 경로에 없으면 매핑하지 말라고 명시  |  |

### Dockerfile

| Command  | Descrtion | Option |
| --- | --- | --- | 
| FROM | 오리지날 이미지 |  | 
| WORKDIR | 작업 디렉토리 생성 |  | 
| COPY |  |  | 
| RUN |  |  | 
| CMD |  |  | 

```Dockerfile

# Dockerfile

FROM node:10

WORKDIR /usr/src/app

# 먼저 따로 해줘야 변경이 없으면 캐쉬 사용
COPY package.json ./
RUN npm install 

COPY ./ ./

CMD ["node" , "server.js"]

```

### Docker compose

| Command | Description | Option |
| --- | --- | --- |
| version | 3버전 사용| |
| services | 컨테이너 묶음 | 예는 redis server, node-app | |
| services > ${컨터에너 이름} | ex) redis server, node-app | |
| build | Dockerfile 위치 | |
| build > context | 도커 이미지를 구성하기 위한 파일들과 폴더들이 있는 위치 |
| build > dockerfile | 도커 파일 지정 |
| ports | 포트 맵핑 (로컬 포트:컨테이너 포트) |
| volumes | 로컬 머신에 있는 파일들 맵핑 |
| stdin_open | 리액트 앱을 끌때 필요(버그 수정) |
| docker-compose up | 이미지 있으면 그냥 올림 | |
| docker-compose up --build | 이미지가 있어도 다시 빌드 후 올림 | |
| docker-compose down | 이미지 내림 | |

실제 redis-client(app 안)에 url을 **redis-server**로 매핑

```yml

# docker-compose.yml

version: "3"
services: 
    redis-server: 
        image: "redis"

    node-app: 
        build: .
        ports: 
            - "5000:8080"

    react-app: 
        build: 
            context: .
            dockerfile: Dockerfile.dev
        ports: 
            - "3000:3000"
        volumes:
            - /usr/src/app/node_modules/
            - ./:/usr/src/app
        stdin_open: true 

    # test도 실시간 반영
    tests:
        build: 
            context: .
            dockerfile: Dockerfile.dev
        volumes:
            - /usr/src/app/node_modules/
            - ./:/usr/src/app
        command: ["npm", "run", "test"]
```

### Dev vs Prod

- Dev
    - `npm run start`로 개발 서버에서 **/src** 폴더 밑의 파일들을 바라보게 함
    - 파일을 변경하면 바로 브라우저에서 적용 됨
    - 개발에 유용한 기능들이 많지만 대신 무거움
- Prod
    - nginx를 이용해서 빌드된(**/build**) 파일을 바라봄
    - 개발과 다르게 필요없는 부분을 빼고 안정적


```Dockerfile

#Dockerfile(운영)

# ===== builder stage

# as ${nicname}은 다음 FROM까지
FROM node:alpine as builder
WORKDIR '/usr/src/app'
COPY package.json ./
RUN npm install
COPY ./ ./
RUN npm run build

# ===== builder stage

# ===== run stage

FROM nginx 
EXPOSE 80
# build된 파일들을 nginx로 복사
# nginx port는 80
COPY --from=builder /usr/src/app/build /usr/share/nginx/html

# ===== run stage

```

### Travis CI 

- local Git -> Github -> Travis CI -> AWS

- Travis CI에 로그인 후 git 연결 활성화

- .travis.yml 작성

    - sudo : 관리자 권한갖기
    - language : 언어(플랫폼)을 선택
    - services : 도커 환경 구성
    - before_install : 스크립트를 실행할 수 있는 환경 만들어줌 (스크립트 실행 전 해야할 일. 여기서는 빌드)
    - script : 실행할 스크립트(테스트 실행)
    - after_success : 테스트 후 할일

    - deploy    
        - provider : 외부 서비스 표시(s3, elasticbeanstalk, firebase ... )
        - region : AWS region
        - app : 생성도니 어플리케이션의 이름
        - env : 
        - bucket_name : 해당 elasticbeanstalk을 위한 s3 버켓 이름(travis에 파일을 압축해서 보냄)
        - bucket_path : 어플리케이션의 이름과 동일
        - on
            - branch : 어떤 브랜치에 Push를 할때 AWS에 배포를 할것인지

    - AWS Security Key(IAM)는 노출되면 안되서 travis 페이지에 직접 넣음(More Options > Environment Variables)

### AWS Elastic Beanstalk 

#### 컨트롤
    - EC2 인스턴스
    - 데이터 베이스
    - Security 그룹
    - Auto-Scaling 그룹
    - 로드 밸런스
