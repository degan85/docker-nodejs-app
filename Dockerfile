FROM node:10

WORKDIR /usr/src/app

# 먼저 따로 해줘야 변경이 없으면 캐쉬 사용
COPY package.json ./
RUN npm install 

COPY ./ ./

CMD ["node" , "server.js"]