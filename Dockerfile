# 1st step
FROM ubuntu:bionic as basic_image

ARG DEBIAN_FRONTEND=noninteractive
ENV LANG C.UTF-8

RUN apt-get clean && apt-get update -y \
  && apt-get install -y openjdk-8-jdk \
  && export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
  && export PATH=$PATH:$JAVA_HOME/bin \
  && apt-get install -y libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev \
  && apt-get install -y libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev

# 2nd step
FROM basic_image as built_image

RUN apt-get install -y cmake g++ git wget tar \
  && apt-get install -y python-dev python-numpy \
  && apt-get install -y ant \
  && mkdir -p /opencv_contrib && cd /opencv_contrib \
  && wget -O opencv_contrib-src.tar.gz "https://github.com/opencv/opencv_contrib/archive/4.5.3.tar.gz" \
  && cd /opencv_contrib && tar -xzf opencv_contrib-4.5.3.tar.gz --strip-components=1 \
  && mkdir -p /opencv && cd /opencv \
  && wget -O opencv-src.tar.gz "https://github.com/opencv/opencv/archive/4.5.3.tar.gz" \
  && cd /opencv  && tar -xzf opencv-4.5.3.tar.gz --strip-components=1 \
  && mkdir build && cd build \
  && cmake -DOPENCV_EXTRA_MODULES_PATH=/opencv_contrib/modules \
          -DBUILD_TIFF=ON \
          -DBUILD_opencv_java=ON \
          -DBUILD_SHARED_LIBS=ON \
          -DWITH_CUDA=OFF \
          -DENABLE_AVX=ON \
          -DWITH_OPENCL=ON \
          -DWITH_IPP=ON \
          -DWITH_TBB=ON \
          -DWITH_EIGEN=ON \
          -DWITH_V4L=ON \
          -DBUILD_TESTS=OFF \
          -DBUILD_PERF_TESTS=OFF \
          -DCMAKE_BUILD_TYPE=RELEASE \
          -DCMAKE_INSTALL_PREFIX=/usr/local/opencv \
          -DBUILD_NEW_PYTHON_SUPPORT=ON \
          -DBUILD_opencv_python3=ON \
          -DPYTHON_EXECUTABLE=$(which python3.6.9) \
          -DPYTHON_INCLUDE_DIR=$(python3.6.9 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
          -DPYTHON_PACKAGES_PATH=$(python3.6.9 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") .. \
  && make -j$(nproc) \
  && make install \
  && rm /opencv/opencv-4.5.3.tar.gz \
  && rm /opencv_contrib/opencv_contrib-4.5.3.tar.gz \
  && rm -r /opencv \
  && rm -r /opencv_contrib

# 3rd step
FROM basic_image

COPY --from=built_image /usr/local/opencv/ /usr/local/opencv/
ENV LD_LIBRARY_PATH=/usr/local/opencv/share/java/opencv4

RUN echo $JAVA_HOME && echo $PATH

CMD /bin/sh
