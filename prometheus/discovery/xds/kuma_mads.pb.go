// Copyright 2021 The Prometheus Authors
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Code generated by protoc-gen-go. DO NOT EDIT.
// versions:
// 	protoc-gen-go v1.25.0
// 	protoc        v3.14.0
// source: observability/v1/mads.proto

// gRPC-removed vendored file from Kuma.

package xds

import (
	context "context"
	reflect "reflect"
	sync "sync"

	v3 "github.com/envoyproxy/go-control-plane/envoy/service/discovery/v3"
	_ "github.com/envoyproxy/protoc-gen-validate/validate"
	_ "google.golang.org/genproto/googleapis/api/annotations"
	protoreflect "google.golang.org/protobuf/reflect/protoreflect"
	protoimpl "google.golang.org/protobuf/runtime/protoimpl"
)

const (
	// Verify that this generated code is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(20 - protoimpl.MinVersion)
	// Verify that runtime/protoimpl is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(protoimpl.MaxVersion - 20)
)

// MADS resource type.
//
// Describes a group of targets on a single service that need to be monitored.
type MonitoringAssignment struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	// Mesh of the dataplane.
	//
	// E.g., `default`
	Mesh string `protobuf:"bytes,2,opt,name=mesh,proto3" json:"mesh,omitempty"`
	// Identifying service the dataplane is proxying.
	//
	// E.g., `backend`
	Service string `protobuf:"bytes,3,opt,name=service,proto3" json:"service,omitempty"`
	// List of targets that need to be monitored.
	Targets []*MonitoringAssignment_Target `protobuf:"bytes,4,rep,name=targets,proto3" json:"targets,omitempty"`
	// Arbitrary Labels associated with every target in the assignment.
	//
	// E.g., `{"zone" : "us-east-1", "team": "infra", "commit_hash": "620506a88"}`.
	Labels map[string]string `protobuf:"bytes,5,rep,name=labels,proto3" json:"labels,omitempty" protobuf_key:"bytes,1,opt,name=key,proto3" protobuf_val:"bytes,2,opt,name=value,proto3"`
}

func (x *MonitoringAssignment) Reset() {
	*x = MonitoringAssignment{}
	if protoimpl.UnsafeEnabled {
		mi := &file_observability_v1_mads_proto_msgTypes[0]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *MonitoringAssignment) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*MonitoringAssignment) ProtoMessage() {}

func (x *MonitoringAssignment) ProtoReflect() protoreflect.Message {
	mi := &file_observability_v1_mads_proto_msgTypes[0]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use MonitoringAssignment.ProtoReflect.Descriptor instead.
func (*MonitoringAssignment) Descriptor() ([]byte, []int) {
	return file_observability_v1_mads_proto_rawDescGZIP(), []int{0}
}

func (x *MonitoringAssignment) GetMesh() string {
	if x != nil {
		return x.Mesh
	}
	return ""
}

func (x *MonitoringAssignment) GetService() string {
	if x != nil {
		return x.Service
	}
	return ""
}

func (x *MonitoringAssignment) GetTargets() []*MonitoringAssignment_Target {
	if x != nil {
		return x.Targets
	}
	return nil
}

func (x *MonitoringAssignment) GetLabels() map[string]string {
	if x != nil {
		return x.Labels
	}
	return nil
}

// Describes a single target that needs to be monitored.
type MonitoringAssignment_Target struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	// E.g., `backend-01`
	Name string `protobuf:"bytes,1,opt,name=name,proto3" json:"name,omitempty"`
	// Scheme on which to scrape the target.
	//E.g., `http`
	Scheme string `protobuf:"bytes,2,opt,name=scheme,proto3" json:"scheme,omitempty"`
	// Address (preferably IP) for the service
	// E.g., `backend.svc` or `10.1.4.32:9090`
	Address string `protobuf:"bytes,3,opt,name=address,proto3" json:"address,omitempty"`
	// Optional path to append to the address for scraping
	//E.g., `/metrics`
	MetricsPath string `protobuf:"bytes,4,opt,name=metrics_path,json=metricsPath,proto3" json:"metrics_path,omitempty"`
	// Arbitrary labels associated with that particular target.
	//
	// E.g.,
	// `{
	//    "commit_hash" : "620506a88",
	//  }`.
	Labels map[string]string `protobuf:"bytes,5,rep,name=labels,proto3" json:"labels,omitempty" protobuf_key:"bytes,1,opt,name=key,proto3" protobuf_val:"bytes,2,opt,name=value,proto3"`
}

func (x *MonitoringAssignment_Target) Reset() {
	*x = MonitoringAssignment_Target{}
	if protoimpl.UnsafeEnabled {
		mi := &file_observability_v1_mads_proto_msgTypes[1]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *MonitoringAssignment_Target) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*MonitoringAssignment_Target) ProtoMessage() {}

func (x *MonitoringAssignment_Target) ProtoReflect() protoreflect.Message {
	mi := &file_observability_v1_mads_proto_msgTypes[1]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use MonitoringAssignment_Target.ProtoReflect.Descriptor instead.
func (*MonitoringAssignment_Target) Descriptor() ([]byte, []int) {
	return file_observability_v1_mads_proto_rawDescGZIP(), []int{0, 0}
}

func (x *MonitoringAssignment_Target) GetName() string {
	if x != nil {
		return x.Name
	}
	return ""
}

func (x *MonitoringAssignment_Target) GetScheme() string {
	if x != nil {
		return x.Scheme
	}
	return ""
}

func (x *MonitoringAssignment_Target) GetAddress() string {
	if x != nil {
		return x.Address
	}
	return ""
}

func (x *MonitoringAssignment_Target) GetMetricsPath() string {
	if x != nil {
		return x.MetricsPath
	}
	return ""
}

func (x *MonitoringAssignment_Target) GetLabels() map[string]string {
	if x != nil {
		return x.Labels
	}
	return nil
}

var File_observability_v1_mads_proto protoreflect.FileDescriptor

var file_observability_v1_mads_proto_rawDesc = []byte{
	0x0a, 0x1b, 0x6f, 0x62, 0x73, 0x65, 0x72, 0x76, 0x61, 0x62, 0x69, 0x6c, 0x69, 0x74, 0x79, 0x2f,
	0x76, 0x31, 0x2f, 0x6d, 0x61, 0x64, 0x73, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x12, 0x15, 0x6b,
	0x75, 0x6d, 0x61, 0x2e, 0x6f, 0x62, 0x73, 0x65, 0x72, 0x76, 0x61, 0x62, 0x69, 0x6c, 0x69, 0x74,
	0x79, 0x2e, 0x76, 0x31, 0x1a, 0x2a, 0x65, 0x6e, 0x76, 0x6f, 0x79, 0x2f, 0x73, 0x65, 0x72, 0x76,
	0x69, 0x63, 0x65, 0x2f, 0x64, 0x69, 0x73, 0x63, 0x6f, 0x76, 0x65, 0x72, 0x79, 0x2f, 0x76, 0x33,
	0x2f, 0x64, 0x69, 0x73, 0x63, 0x6f, 0x76, 0x65, 0x72, 0x79, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f,
	0x1a, 0x1c, 0x67, 0x6f, 0x6f, 0x67, 0x6c, 0x65, 0x2f, 0x61, 0x70, 0x69, 0x2f, 0x61, 0x6e, 0x6e,
	0x6f, 0x74, 0x61, 0x74, 0x69, 0x6f, 0x6e, 0x73, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x1a, 0x17,
	0x76, 0x61, 0x6c, 0x69, 0x64, 0x61, 0x74, 0x65, 0x2f, 0x76, 0x61, 0x6c, 0x69, 0x64, 0x61, 0x74,
	0x65, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x22, 0xd2, 0x04, 0x0a, 0x14, 0x4d, 0x6f, 0x6e, 0x69,
	0x74, 0x6f, 0x72, 0x69, 0x6e, 0x67, 0x41, 0x73, 0x73, 0x69, 0x67, 0x6e, 0x6d, 0x65, 0x6e, 0x74,
	0x12, 0x1b, 0x0a, 0x04, 0x6d, 0x65, 0x73, 0x68, 0x18, 0x02, 0x20, 0x01, 0x28, 0x09, 0x42, 0x07,
	0xfa, 0x42, 0x04, 0x72, 0x02, 0x20, 0x01, 0x52, 0x04, 0x6d, 0x65, 0x73, 0x68, 0x12, 0x21, 0x0a,
	0x07, 0x73, 0x65, 0x72, 0x76, 0x69, 0x63, 0x65, 0x18, 0x03, 0x20, 0x01, 0x28, 0x09, 0x42, 0x07,
	0xfa, 0x42, 0x04, 0x72, 0x02, 0x20, 0x01, 0x52, 0x07, 0x73, 0x65, 0x72, 0x76, 0x69, 0x63, 0x65,
	0x12, 0x4c, 0x0a, 0x07, 0x74, 0x61, 0x72, 0x67, 0x65, 0x74, 0x73, 0x18, 0x04, 0x20, 0x03, 0x28,
	0x0b, 0x32, 0x32, 0x2e, 0x6b, 0x75, 0x6d, 0x61, 0x2e, 0x6f, 0x62, 0x73, 0x65, 0x72, 0x76, 0x61,
	0x62, 0x69, 0x6c, 0x69, 0x74, 0x79, 0x2e, 0x76, 0x31, 0x2e, 0x4d, 0x6f, 0x6e, 0x69, 0x74, 0x6f,
	0x72, 0x69, 0x6e, 0x67, 0x41, 0x73, 0x73, 0x69, 0x67, 0x6e, 0x6d, 0x65, 0x6e, 0x74, 0x2e, 0x54,
	0x61, 0x72, 0x67, 0x65, 0x74, 0x52, 0x07, 0x74, 0x61, 0x72, 0x67, 0x65, 0x74, 0x73, 0x12, 0x4f,
	0x0a, 0x06, 0x6c, 0x61, 0x62, 0x65, 0x6c, 0x73, 0x18, 0x05, 0x20, 0x03, 0x28, 0x0b, 0x32, 0x37,
	0x2e, 0x6b, 0x75, 0x6d, 0x61, 0x2e, 0x6f, 0x62, 0x73, 0x65, 0x72, 0x76, 0x61, 0x62, 0x69, 0x6c,
	0x69, 0x74, 0x79, 0x2e, 0x76, 0x31, 0x2e, 0x4d, 0x6f, 0x6e, 0x69, 0x74, 0x6f, 0x72, 0x69, 0x6e,
	0x67, 0x41, 0x73, 0x73, 0x69, 0x67, 0x6e, 0x6d, 0x65, 0x6e, 0x74, 0x2e, 0x4c, 0x61, 0x62, 0x65,
	0x6c, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x52, 0x06, 0x6c, 0x61, 0x62, 0x65, 0x6c, 0x73, 0x1a,
	0x9f, 0x02, 0x0a, 0x06, 0x54, 0x61, 0x72, 0x67, 0x65, 0x74, 0x12, 0x1b, 0x0a, 0x04, 0x6e, 0x61,
	0x6d, 0x65, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x42, 0x07, 0xfa, 0x42, 0x04, 0x72, 0x02, 0x20,
	0x01, 0x52, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x12, 0x1f, 0x0a, 0x06, 0x73, 0x63, 0x68, 0x65, 0x6d,
	0x65, 0x18, 0x02, 0x20, 0x01, 0x28, 0x09, 0x42, 0x07, 0xfa, 0x42, 0x04, 0x72, 0x02, 0x20, 0x01,
	0x52, 0x06, 0x73, 0x63, 0x68, 0x65, 0x6d, 0x65, 0x12, 0x21, 0x0a, 0x07, 0x61, 0x64, 0x64, 0x72,
	0x65, 0x73, 0x73, 0x18, 0x03, 0x20, 0x01, 0x28, 0x09, 0x42, 0x07, 0xfa, 0x42, 0x04, 0x72, 0x02,
	0x20, 0x01, 0x52, 0x07, 0x61, 0x64, 0x64, 0x72, 0x65, 0x73, 0x73, 0x12, 0x21, 0x0a, 0x0c, 0x6d,
	0x65, 0x74, 0x72, 0x69, 0x63, 0x73, 0x5f, 0x70, 0x61, 0x74, 0x68, 0x18, 0x04, 0x20, 0x01, 0x28,
	0x09, 0x52, 0x0b, 0x6d, 0x65, 0x74, 0x72, 0x69, 0x63, 0x73, 0x50, 0x61, 0x74, 0x68, 0x12, 0x56,
	0x0a, 0x06, 0x6c, 0x61, 0x62, 0x65, 0x6c, 0x73, 0x18, 0x05, 0x20, 0x03, 0x28, 0x0b, 0x32, 0x3e,
	0x2e, 0x6b, 0x75, 0x6d, 0x61, 0x2e, 0x6f, 0x62, 0x73, 0x65, 0x72, 0x76, 0x61, 0x62, 0x69, 0x6c,
	0x69, 0x74, 0x79, 0x2e, 0x76, 0x31, 0x2e, 0x4d, 0x6f, 0x6e, 0x69, 0x74, 0x6f, 0x72, 0x69, 0x6e,
	0x67, 0x41, 0x73, 0x73, 0x69, 0x67, 0x6e, 0x6d, 0x65, 0x6e, 0x74, 0x2e, 0x54, 0x61, 0x72, 0x67,
	0x65, 0x74, 0x2e, 0x4c, 0x61, 0x62, 0x65, 0x6c, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79, 0x52, 0x06,
	0x6c, 0x61, 0x62, 0x65, 0x6c, 0x73, 0x1a, 0x39, 0x0a, 0x0b, 0x4c, 0x61, 0x62, 0x65, 0x6c, 0x73,
	0x45, 0x6e, 0x74, 0x72, 0x79, 0x12, 0x10, 0x0a, 0x03, 0x6b, 0x65, 0x79, 0x18, 0x01, 0x20, 0x01,
	0x28, 0x09, 0x52, 0x03, 0x6b, 0x65, 0x79, 0x12, 0x14, 0x0a, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65,
	0x18, 0x02, 0x20, 0x01, 0x28, 0x09, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x3a, 0x02, 0x38,
	0x01, 0x1a, 0x39, 0x0a, 0x0b, 0x4c, 0x61, 0x62, 0x65, 0x6c, 0x73, 0x45, 0x6e, 0x74, 0x72, 0x79,
	0x12, 0x10, 0x0a, 0x03, 0x6b, 0x65, 0x79, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x52, 0x03, 0x6b,
	0x65, 0x79, 0x12, 0x14, 0x0a, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x02, 0x20, 0x01, 0x28,
	0x09, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x3a, 0x02, 0x38, 0x01, 0x32, 0xe6, 0x03, 0x0a,
	0x24, 0x4d, 0x6f, 0x6e, 0x69, 0x74, 0x6f, 0x72, 0x69, 0x6e, 0x67, 0x41, 0x73, 0x73, 0x69, 0x67,
	0x6e, 0x6d, 0x65, 0x6e, 0x74, 0x44, 0x69, 0x73, 0x63, 0x6f, 0x76, 0x65, 0x72, 0x79, 0x53, 0x65,
	0x72, 0x76, 0x69, 0x63, 0x65, 0x12, 0x89, 0x01, 0x0a, 0x1a, 0x44, 0x65, 0x6c, 0x74, 0x61, 0x4d,
	0x6f, 0x6e, 0x69, 0x74, 0x6f, 0x72, 0x69, 0x6e, 0x67, 0x41, 0x73, 0x73, 0x69, 0x67, 0x6e, 0x6d,
	0x65, 0x6e, 0x74, 0x73, 0x12, 0x31, 0x2e, 0x65, 0x6e, 0x76, 0x6f, 0x79, 0x2e, 0x73, 0x65, 0x72,
	0x76, 0x69, 0x63, 0x65, 0x2e, 0x64, 0x69, 0x73, 0x63, 0x6f, 0x76, 0x65, 0x72, 0x79, 0x2e, 0x76,
	0x33, 0x2e, 0x44, 0x65, 0x6c, 0x74, 0x61, 0x44, 0x69, 0x73, 0x63, 0x6f, 0x76, 0x65, 0x72, 0x79,
	0x52, 0x65, 0x71, 0x75, 0x65, 0x73, 0x74, 0x1a, 0x32, 0x2e, 0x65, 0x6e, 0x76, 0x6f, 0x79, 0x2e,
	0x73, 0x65, 0x72, 0x76, 0x69, 0x63, 0x65, 0x2e, 0x64, 0x69, 0x73, 0x63, 0x6f, 0x76, 0x65, 0x72,
	0x79, 0x2e, 0x76, 0x33, 0x2e, 0x44, 0x65, 0x6c, 0x74, 0x61, 0x44, 0x69, 0x73, 0x63, 0x6f, 0x76,
	0x65, 0x72, 0x79, 0x52, 0x65, 0x73, 0x70, 0x6f, 0x6e, 0x73, 0x65, 0x22, 0x00, 0x28, 0x01, 0x30,
	0x01, 0x12, 0x80, 0x01, 0x0a, 0x1b, 0x53, 0x74, 0x72, 0x65, 0x61, 0x6d, 0x4d, 0x6f, 0x6e, 0x69,
	0x74, 0x6f, 0x72, 0x69, 0x6e, 0x67, 0x41, 0x73, 0x73, 0x69, 0x67, 0x6e, 0x6d, 0x65, 0x6e, 0x74,
	0x73, 0x12, 0x2c, 0x2e, 0x65, 0x6e, 0x76, 0x6f, 0x79, 0x2e, 0x73, 0x65, 0x72, 0x76, 0x69, 0x63,
	0x65, 0x2e, 0x64, 0x69, 0x73, 0x63, 0x6f, 0x76, 0x65, 0x72, 0x79, 0x2e, 0x76, 0x33, 0x2e, 0x44,
	0x69, 0x73, 0x63, 0x6f, 0x76, 0x65, 0x72, 0x79, 0x52, 0x65, 0x71, 0x75, 0x65, 0x73, 0x74, 0x1a,
	0x2d, 0x2e, 0x65, 0x6e, 0x76, 0x6f, 0x79, 0x2e, 0x73, 0x65, 0x72, 0x76, 0x69, 0x63, 0x65, 0x2e,
	0x64, 0x69, 0x73, 0x63, 0x6f, 0x76, 0x65, 0x72, 0x79, 0x2e, 0x76, 0x33, 0x2e, 0x44, 0x69, 0x73,
	0x63, 0x6f, 0x76, 0x65, 0x72, 0x79, 0x52, 0x65, 0x73, 0x70, 0x6f, 0x6e, 0x73, 0x65, 0x22, 0x00,
	0x28, 0x01, 0x30, 0x01, 0x12, 0xae, 0x01, 0x0a, 0x1a, 0x46, 0x65, 0x74, 0x63, 0x68, 0x4d, 0x6f,
	0x6e, 0x69, 0x74, 0x6f, 0x72, 0x69, 0x6e, 0x67, 0x41, 0x73, 0x73, 0x69, 0x67, 0x6e, 0x6d, 0x65,
	0x6e, 0x74, 0x73, 0x12, 0x2c, 0x2e, 0x65, 0x6e, 0x76, 0x6f, 0x79, 0x2e, 0x73, 0x65, 0x72, 0x76,
	0x69, 0x63, 0x65, 0x2e, 0x64, 0x69, 0x73, 0x63, 0x6f, 0x76, 0x65, 0x72, 0x79, 0x2e, 0x76, 0x33,
	0x2e, 0x44, 0x69, 0x73, 0x63, 0x6f, 0x76, 0x65, 0x72, 0x79, 0x52, 0x65, 0x71, 0x75, 0x65, 0x73,
	0x74, 0x1a, 0x2d, 0x2e, 0x65, 0x6e, 0x76, 0x6f, 0x79, 0x2e, 0x73, 0x65, 0x72, 0x76, 0x69, 0x63,
	0x65, 0x2e, 0x64, 0x69, 0x73, 0x63, 0x6f, 0x76, 0x65, 0x72, 0x79, 0x2e, 0x76, 0x33, 0x2e, 0x44,
	0x69, 0x73, 0x63, 0x6f, 0x76, 0x65, 0x72, 0x79, 0x52, 0x65, 0x73, 0x70, 0x6f, 0x6e, 0x73, 0x65,
	0x22, 0x33, 0x82, 0xd3, 0xe4, 0x93, 0x02, 0x24, 0x22, 0x22, 0x2f, 0x76, 0x33, 0x2f, 0x64, 0x69,
	0x73, 0x63, 0x6f, 0x76, 0x65, 0x72, 0x79, 0x3a, 0x6d, 0x6f, 0x6e, 0x69, 0x74, 0x6f, 0x72, 0x69,
	0x6e, 0x67, 0x61, 0x73, 0x73, 0x69, 0x67, 0x6e, 0x6d, 0x65, 0x6e, 0x74, 0x82, 0xd3, 0xe4, 0x93,
	0x02, 0x03, 0x3a, 0x01, 0x2a, 0x42, 0x04, 0x5a, 0x02, 0x76, 0x31, 0x62, 0x06, 0x70, 0x72, 0x6f,
	0x74, 0x6f, 0x33,
}

var (
	file_observability_v1_mads_proto_rawDescOnce sync.Once
	file_observability_v1_mads_proto_rawDescData = file_observability_v1_mads_proto_rawDesc
)

func file_observability_v1_mads_proto_rawDescGZIP() []byte {
	file_observability_v1_mads_proto_rawDescOnce.Do(func() {
		file_observability_v1_mads_proto_rawDescData = protoimpl.X.CompressGZIP(file_observability_v1_mads_proto_rawDescData)
	})
	return file_observability_v1_mads_proto_rawDescData
}

var file_observability_v1_mads_proto_msgTypes = make([]protoimpl.MessageInfo, 4)
var file_observability_v1_mads_proto_goTypes = []interface{}{
	(*MonitoringAssignment)(nil),        // 0: kuma.observability.v1.MonitoringAssignment
	(*MonitoringAssignment_Target)(nil), // 1: kuma.observability.v1.MonitoringAssignment.Target
	nil,                                 // 2: kuma.observability.v1.MonitoringAssignment.LabelsEntry
	nil,                                 // 3: kuma.observability.v1.MonitoringAssignment.Target.LabelsEntry
	(*v3.DeltaDiscoveryRequest)(nil),    // 4: envoy.service.discovery.v3.DeltaDiscoveryRequest
	(*v3.DiscoveryRequest)(nil),         // 5: envoy.service.discovery.v3.DiscoveryRequest
	(*v3.DeltaDiscoveryResponse)(nil),   // 6: envoy.service.discovery.v3.DeltaDiscoveryResponse
	(*v3.DiscoveryResponse)(nil),        // 7: envoy.service.discovery.v3.DiscoveryResponse
}
var file_observability_v1_mads_proto_depIdxs = []int32{
	1, // 0: kuma.observability.v1.MonitoringAssignment.targets:type_name -> kuma.observability.v1.MonitoringAssignment.Target
	2, // 1: kuma.observability.v1.MonitoringAssignment.labels:type_name -> kuma.observability.v1.MonitoringAssignment.LabelsEntry
	3, // 2: kuma.observability.v1.MonitoringAssignment.Target.labels:type_name -> kuma.observability.v1.MonitoringAssignment.Target.LabelsEntry
	4, // 3: kuma.observability.v1.MonitoringAssignmentDiscoveryService.DeltaMonitoringAssignments:input_type -> envoy.service.discovery.v3.DeltaDiscoveryRequest
	5, // 4: kuma.observability.v1.MonitoringAssignmentDiscoveryService.StreamMonitoringAssignments:input_type -> envoy.service.discovery.v3.DiscoveryRequest
	5, // 5: kuma.observability.v1.MonitoringAssignmentDiscoveryService.FetchMonitoringAssignments:input_type -> envoy.service.discovery.v3.DiscoveryRequest
	6, // 6: kuma.observability.v1.MonitoringAssignmentDiscoveryService.DeltaMonitoringAssignments:output_type -> envoy.service.discovery.v3.DeltaDiscoveryResponse
	7, // 7: kuma.observability.v1.MonitoringAssignmentDiscoveryService.StreamMonitoringAssignments:output_type -> envoy.service.discovery.v3.DiscoveryResponse
	7, // 8: kuma.observability.v1.MonitoringAssignmentDiscoveryService.FetchMonitoringAssignments:output_type -> envoy.service.discovery.v3.DiscoveryResponse
	6, // [6:9] is the sub-list for method output_type
	3, // [3:6] is the sub-list for method input_type
	3, // [3:3] is the sub-list for extension type_name
	3, // [3:3] is the sub-list for extension extendee
	0, // [0:3] is the sub-list for field type_name
}

func init() { file_observability_v1_mads_proto_init() }
func file_observability_v1_mads_proto_init() {
	if File_observability_v1_mads_proto != nil {
		return
	}
	if !protoimpl.UnsafeEnabled {
		file_observability_v1_mads_proto_msgTypes[0].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*MonitoringAssignment); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_observability_v1_mads_proto_msgTypes[1].Exporter = func(v interface{}, i int) interface{} {
			switch v := v.(*MonitoringAssignment_Target); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
	}
	type x struct{}
	out := protoimpl.TypeBuilder{
		File: protoimpl.DescBuilder{
			GoPackagePath: reflect.TypeOf(x{}).PkgPath(),
			RawDescriptor: file_observability_v1_mads_proto_rawDesc,
			NumEnums:      0,
			NumMessages:   4,
			NumExtensions: 0,
			NumServices:   1,
		},
		GoTypes:           file_observability_v1_mads_proto_goTypes,
		DependencyIndexes: file_observability_v1_mads_proto_depIdxs,
		MessageInfos:      file_observability_v1_mads_proto_msgTypes,
	}.Build()
	File_observability_v1_mads_proto = out.File
	file_observability_v1_mads_proto_rawDesc = nil
	file_observability_v1_mads_proto_goTypes = nil
	file_observability_v1_mads_proto_depIdxs = nil
}

// MonitoringAssignmentDiscoveryServiceServer is the server API for MonitoringAssignmentDiscoveryService service.
type MonitoringAssignmentDiscoveryServiceServer interface {
	// HTTP
	FetchMonitoringAssignments(context.Context, *v3.DiscoveryRequest) (*v3.DiscoveryResponse, error)
}