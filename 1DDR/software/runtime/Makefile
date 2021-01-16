# Amazon FPGA Hardware Development Kit
#
# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.

INCLUDES = -I$(SDK_DIR)/userspace/include -I$(FLETCHER_AWS_DIR)/runtime/runtime/src

CC = g++
CPPFLAGS = -DCONFIG_LOGLEVEL=4 -g -Wall -Werror $(INCLUDES)

#the -L library include directories are only needed if the platform libraries are not installed
LDLIBS = -L$(FLETCHER_AWS_DIR)/runtime/runtime/build -lfpga_mgmt -lfletcher -lfletcher_aws

SRC = sum.cpp
OBJ = $(SRC:.cpp=.o)


all: sum check_env $(BIN)

sum: $(OBJ)
	$(CC) $(CFLAGS) -o sum sum.o $(LDFLAGS) $(LDLIBS)

clean:
	rm -f *.o sum

check_env:
ifndef SDK_DIR
	$(error SDK_DIR is undefined. Try "source sdk_setup.sh" to set the software environment)
endif
ifndef FLETCHER_AWS_DIR
	$(error Environment variable FLETCHER_AWS_DIR not set. please source fletcher-aws sourceme.sh)
endif

