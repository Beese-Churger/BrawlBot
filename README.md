# BrawlBot
BrawlBot is a serverless discord bot using the C++ runtime for Lambda by AWS to interact with the BrawlStars API.

Use BrawlBot in your server to check current events going on inside BrawlStars.

# Requirements
**A C++11 compiler, either GCC 5.x or later or Clang 3.3 or later.**

Ubuntu | Bash
```
$ sudo apt-get install gcc libcurl4-openssl-dev
```

**CMake v.3.5 or later.**

Ubuntu | Bash
```
$ sudo apt-get install cmake
```

**Download and compile the C++ AWS runtime.**

Ubuntu | Bash
```
$ cd ~ 
$ git clone https://github.com/awslabs/aws-lambda-cpp.git
$ cd aws-lambda-cpp
$ mkdir build
$ cd build
$ cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF \
   -DCMAKE_INSTALL_PREFIX=~/out
$ make && make install
```

# Build

To build this executable, create a build directory and run CMake from there:

Ubuntu | Bash
```
$ mkdir build
$ cd build
$ cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=~/out
$ make
```
This compiles and links the executable in release mode.
To package this executable along with all its dependencies, run the following command:

Ubuntu | Bash
```
$ make aws-lambda-package-{PROJECT_NAME}
```
