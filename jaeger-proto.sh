#!/usr/bin/env bash

# This hack script assumes you have cloned the jaeger repo in the "src" folder relative to GOPATH

CLIENT_SRC=${GOPATH}/src/github.com/lucasponce/jaeger-backend-client
JAEGER_SRC=${GOPATH}/src/github.com/jaegertracing/jaeger

for R in ${KIALI_SRC} ${CLIENT_SRC}
do
  if [ ! -d $R ]
  then
    echo "Repo $R is not found"
    exit 1
  fi
done

# The jaeger backend client will import minimal dependencies to create a stub client for jaeger grpc query
# The generated grpc uses some auxiliary classes in the jaeger "model" package that are cloned into the backend client

for D in ${CLIENT_SRC}/model/converter/json ${CLIENT_SRC}/model/json ${CLIENT_SRC}/proto-gen/api_v2
do
  rm -Rf $D
  mkdir -p $D
done

# Copy the jaeger "model" minimal dependencies for the client grpc proto

for F in hash ids keyvalue process span spanref time model.pb
do
  cp ${JAEGER_SRC}/model/${F}.go ${CLIENT_SRC}/model
done

for F in from_domain process_hashtable
do
  cp  ${JAEGER_SRC}/model/converter/json/${F}.go ${CLIENT_SRC}/model/converter/json
  # Redirect imports in the cloned files
  sed -i 's/github\.com\/jaegertracing\/jaeger/github\.com\/lucasponce\/jaeger-backend-client/g' ${CLIENT_SRC}/model/converter/json/${F}.go
done

for F in model
do
  cp  ${JAEGER_SRC}/model/json/${F}.go ${CLIENT_SRC}/model/json
done

# Copy the grpc proto from jaeger

for F in query.pb
do
  cp ${JAEGER_SRC}/proto-gen/api_v2/${F}.go ${CLIENT_SRC}/proto-gen/api_v2
done

# Post task to fix the proper imports to Span and DependencyLink structs in the generated query.pb.go

sed -i 's/github\.com\/jaegertracing\/jaeger/github\.com\/lucasponce\/jaeger-backend-client/g' ${CLIENT_SRC}/proto-gen/api_v2/query.pb.go