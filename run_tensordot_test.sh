#!/usr/bin/env bash
# Copyright 2020 The TensorFlow Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ==============================================================================
set -e
set -x

N_BUILD_JOBS=$(grep -c ^processor /proc/cpuinfo)
#TF_GPU_COUNT=$(lspci|grep 'controller'|grep 'AMD/ATI'|wc -l)
TF_GPU_COUNT=1
TF_TESTS_PER_GPU=1
N_TEST_JOBS=$(expr ${TF_GPU_COUNT} \* ${TF_TESTS_PER_GPU})

echo ""
echo "Bazel will use ${N_BUILD_JOBS} concurrent build job(s) and ${N_TEST_JOBS} concurrent test job(s)."
echo ""

# First positional argument (if any) specifies the ROCM_INSTALL_DIR
ROCM_INSTALL_DIR=/opt/rocm-5.6.0
if [[ -n $1 ]]; then
    ROCM_INSTALL_DIR=$1
fi

# Run configure.
export PYTHON_BIN_PATH=`which python3`

PYTHON_VERSION=`python3 -c "import sys;print(f'{sys.version_info.major}.{sys.version_info.minor}')"`
export TF_PYTHON_VERSION=$PYTHON_VERSION
export TF_NEED_ROCM=1
export TF_NEED_CLANG=0
export ROCM_PATH=$ROCM_INSTALL_DIR

yes "" | $PYTHON_BIN_PATH configure.py

      #--test_env=MIOPEN_DEBUG_CONV_WINOGRAD=0 \
      #--test_env=MIOPEN_DEBUG_CONV_FFT=0 \
      #--test_env=MIOPEN_DEBUG_CONV_GEMM=0 \
      #--test_env=MIOPEN_DEBUG_CONV_IMPLICIT_GEMM=0 \
      #--test_env=MIOPEN_DEBUG_CONV_DIRECT=1 \
# Run bazel test command. Double test timeouts to avoid flakes.
bazel test \
      --config=rocm \
      -k \
      --test_tag_filters=gpu,-no_oss,-oss_excluded,-oss_serial,-no_gpu,-no_rocm,-benchmark-test,-rocm_multi_gpu,-tpu,-v1only \
      --jobs=${N_BUILD_JOBS} \
      --local_test_jobs=${N_TEST_JOBS} \
      --test_env=TF_GPU_COUNT=$TF_GPU_COUNT \
      --test_env=TF_TESTS_PER_GPU=$TF_TESTS_PER_GPU \
      --test_env=HSA_TOOLS_LIB=libroctracer64.so \
			--test_env=AMD_SERIALIZE_KERNEL=3 \
      --test_env=AMD_SERIALIZE_COPY=3 \
			--test_env=ROCBLAS_LAYER=2 \
      --test_env=TENSILE_DB=0x8000 \
      --test_env=MIOPEN_ENABLE_LOGGING_CMD=1 \
      --test_env=MIOPEN_ENABLE_LOGGING=1 \
      --test_env=MIOPEN_LOG_LEVEL=7 \
      --test_env=TF_PYTHON_VERSION=$PYTHON_VERSION \
      --test_timeout 920,2400,7200,9600 \
      --build_tests_only \
      --test_output=errors \
      --test_sharding_strategy=disabled \
      --test_size_filters=small,medium,large \
      --run_under=//tensorflow/tools/ci_build/gpu_build:parallel_gpu_execute \
      -- \
//tensorflow/python/kernel_tests/math_ops:tensordot_op_test_gpu \
#//tensorflow/compiler/tests:qr_op_test_gpu \
#//tensorflow/python/kernel_tests/linalg:matrix_solve_ls_op_test_gpu \
#//tensorflow/python/kernel_tests/array_ops:init_ops_test_gpu \
#//tensorflow/compiler/xla/tests:convolution_test_cudnn_frontend_disabled_gpu \
#//tensorflow/compiler/xla/tests:convolution_test_gpu \
#//tensorflow/compiler/xla/tests:convolution_test_gpu_alternative_layout_gpu \
#//tensorflow/compiler/xla/service/gpu/tests:gpu_kernel_tiling_test_gpu \
#//tensorflow/compiler/xla/tests:conv_depthwise_test_gpu \
#//tensorflow/core/grappler/optimizers:remapper_test_gpu \
#//tensorflow/dtensor/python/tests:multi_client_test_2gpus \
#//tensorflow/python/distribute/experimental:multi_worker_mirrored_strategy_test_2gpus \
#//tensorflow/python/grappler:auto_mixed_precision_test_gpu \
#//tensorflow/python/grappler:remapper_test_gpu \



      #//tensorflow/... \
      #-//tensorflow/python/integration_testing/... \
      #-//tensorflow/core/tpu/... \
      #-//tensorflow/lite/... \
      #-//tensorflow/compiler/tf2tensorrt/... \
      #-//tensorflow/dtensor/python/tests:multi_client_test_nccl_2gpus
