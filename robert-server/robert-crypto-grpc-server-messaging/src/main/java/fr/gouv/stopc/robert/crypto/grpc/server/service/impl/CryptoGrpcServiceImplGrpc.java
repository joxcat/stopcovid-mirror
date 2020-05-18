package fr.gouv.stopc.robert.crypto.grpc.server.service.impl;

import static io.grpc.MethodDescriptor.generateFullMethodName;
import static io.grpc.stub.ClientCalls.asyncServerStreamingCall;
import static io.grpc.stub.ClientCalls.asyncUnaryCall;
import static io.grpc.stub.ClientCalls.blockingServerStreamingCall;
import static io.grpc.stub.ClientCalls.blockingUnaryCall;
import static io.grpc.stub.ClientCalls.futureUnaryCall;
import static io.grpc.stub.ServerCalls.asyncServerStreamingCall;
import static io.grpc.stub.ServerCalls.asyncUnaryCall;
import static io.grpc.stub.ServerCalls.asyncUnimplementedUnaryCall;

import fr.gouv.stopc.robert.crypto.grpc.server.request.DecryptCountryCodeRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.DecryptEBIDRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.EncryptCountryCodeRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.EphemeralTupleRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.GenerateEBIDRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.MacEsrValidationRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.MacHelloGenerationRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.MacHelloValidationRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.request.MacValidationForTypeRequest;
import fr.gouv.stopc.robert.crypto.grpc.server.response.DecryptCountryCodeResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.response.EBIDResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.response.EncryptCountryCodeResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.response.EphemeralTupleResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.response.MacHelloGenerationResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.response.MacValidationResponse;
import fr.gouv.stopc.robert.crypto.grpc.server.service.CryptoGrpcService;

/**
 * <pre>
 * The greeting service definition.
 * </pre>
 */
@javax.annotation.Generated(
    value = "by gRPC proto compiler (version 1.29.0)",
    comments = "Source: crypto_service.proto")
public final class CryptoGrpcServiceImplGrpc {

  private CryptoGrpcServiceImplGrpc() {}

  public static final String SERVICE_NAME = "robert.server.crypto.CryptoGrpcServiceImpl";

  // Static method descriptors that strictly reflect the proto.
  private static volatile io.grpc.MethodDescriptor<EphemeralTupleRequest,
      EphemeralTupleResponse> getGenerateEphemeralTupleMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "generateEphemeralTuple",
      requestType = EphemeralTupleRequest.class,
      responseType = EphemeralTupleResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.SERVER_STREAMING)
  public static io.grpc.MethodDescriptor<EphemeralTupleRequest,
      EphemeralTupleResponse> getGenerateEphemeralTupleMethod() {
    io.grpc.MethodDescriptor<EphemeralTupleRequest, EphemeralTupleResponse> getGenerateEphemeralTupleMethod;
    if ((getGenerateEphemeralTupleMethod = CryptoGrpcServiceImplGrpc.getGenerateEphemeralTupleMethod) == null) {
      synchronized (CryptoGrpcServiceImplGrpc.class) {
        if ((getGenerateEphemeralTupleMethod = CryptoGrpcServiceImplGrpc.getGenerateEphemeralTupleMethod) == null) {
          CryptoGrpcServiceImplGrpc.getGenerateEphemeralTupleMethod = getGenerateEphemeralTupleMethod =
              io.grpc.MethodDescriptor.<EphemeralTupleRequest, EphemeralTupleResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.SERVER_STREAMING)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "generateEphemeralTuple"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  EphemeralTupleRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  EphemeralTupleResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CryptoGrpcServiceImplMethodDescriptorSupplier("generateEphemeralTuple"))
              .build();
        }
      }
    }
    return getGenerateEphemeralTupleMethod;
  }

  private static volatile io.grpc.MethodDescriptor<GenerateEBIDRequest,
      EBIDResponse> getGenerateEBIDMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "generateEBID",
      requestType = GenerateEBIDRequest.class,
      responseType = EBIDResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.UNARY)
  public static io.grpc.MethodDescriptor<GenerateEBIDRequest,
      EBIDResponse> getGenerateEBIDMethod() {
    io.grpc.MethodDescriptor<GenerateEBIDRequest, EBIDResponse> getGenerateEBIDMethod;
    if ((getGenerateEBIDMethod = CryptoGrpcServiceImplGrpc.getGenerateEBIDMethod) == null) {
      synchronized (CryptoGrpcServiceImplGrpc.class) {
        if ((getGenerateEBIDMethod = CryptoGrpcServiceImplGrpc.getGenerateEBIDMethod) == null) {
          CryptoGrpcServiceImplGrpc.getGenerateEBIDMethod = getGenerateEBIDMethod =
              io.grpc.MethodDescriptor.<GenerateEBIDRequest, EBIDResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.UNARY)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "generateEBID"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  GenerateEBIDRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  EBIDResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CryptoGrpcServiceImplMethodDescriptorSupplier("generateEBID"))
              .build();
        }
      }
    }
    return getGenerateEBIDMethod;
  }

  private static volatile io.grpc.MethodDescriptor<DecryptEBIDRequest,
      EBIDResponse> getDecryptEBIDMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "decryptEBID",
      requestType = DecryptEBIDRequest.class,
      responseType = EBIDResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.UNARY)
  public static io.grpc.MethodDescriptor<DecryptEBIDRequest,
      EBIDResponse> getDecryptEBIDMethod() {
    io.grpc.MethodDescriptor<DecryptEBIDRequest, EBIDResponse> getDecryptEBIDMethod;
    if ((getDecryptEBIDMethod = CryptoGrpcServiceImplGrpc.getDecryptEBIDMethod) == null) {
      synchronized (CryptoGrpcServiceImplGrpc.class) {
        if ((getDecryptEBIDMethod = CryptoGrpcServiceImplGrpc.getDecryptEBIDMethod) == null) {
          CryptoGrpcServiceImplGrpc.getDecryptEBIDMethod = getDecryptEBIDMethod =
              io.grpc.MethodDescriptor.<DecryptEBIDRequest, EBIDResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.UNARY)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "decryptEBID"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  DecryptEBIDRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  EBIDResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CryptoGrpcServiceImplMethodDescriptorSupplier("decryptEBID"))
              .build();
        }
      }
    }
    return getDecryptEBIDMethod;
  }

  private static volatile io.grpc.MethodDescriptor<EncryptCountryCodeRequest,
      EncryptCountryCodeResponse> getEncryptCountryCodeMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "encryptCountryCode",
      requestType = EncryptCountryCodeRequest.class,
      responseType = EncryptCountryCodeResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.UNARY)
  public static io.grpc.MethodDescriptor<EncryptCountryCodeRequest,
      EncryptCountryCodeResponse> getEncryptCountryCodeMethod() {
    io.grpc.MethodDescriptor<EncryptCountryCodeRequest, EncryptCountryCodeResponse> getEncryptCountryCodeMethod;
    if ((getEncryptCountryCodeMethod = CryptoGrpcServiceImplGrpc.getEncryptCountryCodeMethod) == null) {
      synchronized (CryptoGrpcServiceImplGrpc.class) {
        if ((getEncryptCountryCodeMethod = CryptoGrpcServiceImplGrpc.getEncryptCountryCodeMethod) == null) {
          CryptoGrpcServiceImplGrpc.getEncryptCountryCodeMethod = getEncryptCountryCodeMethod =
              io.grpc.MethodDescriptor.<EncryptCountryCodeRequest, EncryptCountryCodeResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.UNARY)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "encryptCountryCode"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  EncryptCountryCodeRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  EncryptCountryCodeResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CryptoGrpcServiceImplMethodDescriptorSupplier("encryptCountryCode"))
              .build();
        }
      }
    }
    return getEncryptCountryCodeMethod;
  }

  private static volatile io.grpc.MethodDescriptor<DecryptCountryCodeRequest,
      DecryptCountryCodeResponse> getDecryptCountryCodeMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "decryptCountryCode",
      requestType = DecryptCountryCodeRequest.class,
      responseType = DecryptCountryCodeResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.UNARY)
  public static io.grpc.MethodDescriptor<DecryptCountryCodeRequest,
      DecryptCountryCodeResponse> getDecryptCountryCodeMethod() {
    io.grpc.MethodDescriptor<DecryptCountryCodeRequest, DecryptCountryCodeResponse> getDecryptCountryCodeMethod;
    if ((getDecryptCountryCodeMethod = CryptoGrpcServiceImplGrpc.getDecryptCountryCodeMethod) == null) {
      synchronized (CryptoGrpcServiceImplGrpc.class) {
        if ((getDecryptCountryCodeMethod = CryptoGrpcServiceImplGrpc.getDecryptCountryCodeMethod) == null) {
          CryptoGrpcServiceImplGrpc.getDecryptCountryCodeMethod = getDecryptCountryCodeMethod =
              io.grpc.MethodDescriptor.<DecryptCountryCodeRequest, DecryptCountryCodeResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.UNARY)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "decryptCountryCode"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  DecryptCountryCodeRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  DecryptCountryCodeResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CryptoGrpcServiceImplMethodDescriptorSupplier("decryptCountryCode"))
              .build();
        }
      }
    }
    return getDecryptCountryCodeMethod;
  }

  private static volatile io.grpc.MethodDescriptor<MacHelloGenerationRequest,
      MacHelloGenerationResponse> getGenerateMacHelloMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "generateMacHello",
      requestType = MacHelloGenerationRequest.class,
      responseType = MacHelloGenerationResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.UNARY)
  public static io.grpc.MethodDescriptor<MacHelloGenerationRequest,
      MacHelloGenerationResponse> getGenerateMacHelloMethod() {
    io.grpc.MethodDescriptor<MacHelloGenerationRequest, MacHelloGenerationResponse> getGenerateMacHelloMethod;
    if ((getGenerateMacHelloMethod = CryptoGrpcServiceImplGrpc.getGenerateMacHelloMethod) == null) {
      synchronized (CryptoGrpcServiceImplGrpc.class) {
        if ((getGenerateMacHelloMethod = CryptoGrpcServiceImplGrpc.getGenerateMacHelloMethod) == null) {
          CryptoGrpcServiceImplGrpc.getGenerateMacHelloMethod = getGenerateMacHelloMethod =
              io.grpc.MethodDescriptor.<MacHelloGenerationRequest, MacHelloGenerationResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.UNARY)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "generateMacHello"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  MacHelloGenerationRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  MacHelloGenerationResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CryptoGrpcServiceImplMethodDescriptorSupplier("generateMacHello"))
              .build();
        }
      }
    }
    return getGenerateMacHelloMethod;
  }

  private static volatile io.grpc.MethodDescriptor<MacHelloValidationRequest,
      MacValidationResponse> getValidateMacHelloMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "validateMacHello",
      requestType = MacHelloValidationRequest.class,
      responseType = MacValidationResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.UNARY)
  public static io.grpc.MethodDescriptor<MacHelloValidationRequest,
      MacValidationResponse> getValidateMacHelloMethod() {
    io.grpc.MethodDescriptor<MacHelloValidationRequest, MacValidationResponse> getValidateMacHelloMethod;
    if ((getValidateMacHelloMethod = CryptoGrpcServiceImplGrpc.getValidateMacHelloMethod) == null) {
      synchronized (CryptoGrpcServiceImplGrpc.class) {
        if ((getValidateMacHelloMethod = CryptoGrpcServiceImplGrpc.getValidateMacHelloMethod) == null) {
          CryptoGrpcServiceImplGrpc.getValidateMacHelloMethod = getValidateMacHelloMethod =
              io.grpc.MethodDescriptor.<MacHelloValidationRequest, MacValidationResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.UNARY)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "validateMacHello"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  MacHelloValidationRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  MacValidationResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CryptoGrpcServiceImplMethodDescriptorSupplier("validateMacHello"))
              .build();
        }
      }
    }
    return getValidateMacHelloMethod;
  }

  private static volatile io.grpc.MethodDescriptor<MacEsrValidationRequest,
      MacValidationResponse> getValidateMacEsrMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "validateMacEsr",
      requestType = MacEsrValidationRequest.class,
      responseType = MacValidationResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.UNARY)
  public static io.grpc.MethodDescriptor<MacEsrValidationRequest,
      MacValidationResponse> getValidateMacEsrMethod() {
    io.grpc.MethodDescriptor<MacEsrValidationRequest, MacValidationResponse> getValidateMacEsrMethod;
    if ((getValidateMacEsrMethod = CryptoGrpcServiceImplGrpc.getValidateMacEsrMethod) == null) {
      synchronized (CryptoGrpcServiceImplGrpc.class) {
        if ((getValidateMacEsrMethod = CryptoGrpcServiceImplGrpc.getValidateMacEsrMethod) == null) {
          CryptoGrpcServiceImplGrpc.getValidateMacEsrMethod = getValidateMacEsrMethod =
              io.grpc.MethodDescriptor.<MacEsrValidationRequest, MacValidationResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.UNARY)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "validateMacEsr"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  MacEsrValidationRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  MacValidationResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CryptoGrpcServiceImplMethodDescriptorSupplier("validateMacEsr"))
              .build();
        }
      }
    }
    return getValidateMacEsrMethod;
  }

  private static volatile io.grpc.MethodDescriptor<MacValidationForTypeRequest,
      MacValidationResponse> getValidateMacForTypeMethod;

  @io.grpc.stub.annotations.RpcMethod(
      fullMethodName = SERVICE_NAME + '/' + "validateMacForType",
      requestType = MacValidationForTypeRequest.class,
      responseType = MacValidationResponse.class,
      methodType = io.grpc.MethodDescriptor.MethodType.UNARY)
  public static io.grpc.MethodDescriptor<MacValidationForTypeRequest,
      MacValidationResponse> getValidateMacForTypeMethod() {
    io.grpc.MethodDescriptor<MacValidationForTypeRequest, MacValidationResponse> getValidateMacForTypeMethod;
    if ((getValidateMacForTypeMethod = CryptoGrpcServiceImplGrpc.getValidateMacForTypeMethod) == null) {
      synchronized (CryptoGrpcServiceImplGrpc.class) {
        if ((getValidateMacForTypeMethod = CryptoGrpcServiceImplGrpc.getValidateMacForTypeMethod) == null) {
          CryptoGrpcServiceImplGrpc.getValidateMacForTypeMethod = getValidateMacForTypeMethod =
              io.grpc.MethodDescriptor.<MacValidationForTypeRequest, MacValidationResponse>newBuilder()
              .setType(io.grpc.MethodDescriptor.MethodType.UNARY)
              .setFullMethodName(generateFullMethodName(SERVICE_NAME, "validateMacForType"))
              .setSampledToLocalTracing(true)
              .setRequestMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  MacValidationForTypeRequest.getDefaultInstance()))
              .setResponseMarshaller(io.grpc.protobuf.ProtoUtils.marshaller(
                  MacValidationResponse.getDefaultInstance()))
              .setSchemaDescriptor(new CryptoGrpcServiceImplMethodDescriptorSupplier("validateMacForType"))
              .build();
        }
      }
    }
    return getValidateMacForTypeMethod;
  }

  /**
   * Creates a new async stub that supports all call types for the service
   */
  public static CryptoGrpcServiceImplStub newStub(io.grpc.Channel channel) {
    io.grpc.stub.AbstractStub.StubFactory<CryptoGrpcServiceImplStub> factory =
      new io.grpc.stub.AbstractStub.StubFactory<CryptoGrpcServiceImplStub>() {
        @java.lang.Override
        public CryptoGrpcServiceImplStub newStub(io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
          return new CryptoGrpcServiceImplStub(channel, callOptions);
        }
      };
    return CryptoGrpcServiceImplStub.newStub(factory, channel);
  }

  /**
   * Creates a new blocking-style stub that supports unary and streaming output calls on the service
   */
  public static CryptoGrpcServiceImplBlockingStub newBlockingStub(
      io.grpc.Channel channel) {
    io.grpc.stub.AbstractStub.StubFactory<CryptoGrpcServiceImplBlockingStub> factory =
      new io.grpc.stub.AbstractStub.StubFactory<CryptoGrpcServiceImplBlockingStub>() {
        @java.lang.Override
        public CryptoGrpcServiceImplBlockingStub newStub(io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
          return new CryptoGrpcServiceImplBlockingStub(channel, callOptions);
        }
      };
    return CryptoGrpcServiceImplBlockingStub.newStub(factory, channel);
  }

  /**
   * Creates a new ListenableFuture-style stub that supports unary calls on the service
   */
  public static CryptoGrpcServiceImplFutureStub newFutureStub(
      io.grpc.Channel channel) {
    io.grpc.stub.AbstractStub.StubFactory<CryptoGrpcServiceImplFutureStub> factory =
      new io.grpc.stub.AbstractStub.StubFactory<CryptoGrpcServiceImplFutureStub>() {
        @java.lang.Override
        public CryptoGrpcServiceImplFutureStub newStub(io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
          return new CryptoGrpcServiceImplFutureStub(channel, callOptions);
        }
      };
    return CryptoGrpcServiceImplFutureStub.newStub(factory, channel);
  }

  /**
   * <pre>
   * The greeting service definition.
   * </pre>
   */
  public static abstract class CryptoGrpcServiceImplImplBase implements io.grpc.BindableService {

    /**
     * <pre>
     * Streams a many greetings
     * </pre>
     */
    public void generateEphemeralTuple(EphemeralTupleRequest request,
        io.grpc.stub.StreamObserver<EphemeralTupleResponse> responseObserver) {
      asyncUnimplementedUnaryCall(getGenerateEphemeralTupleMethod(), responseObserver);
    }

    /**
     */
    public void generateEBID(GenerateEBIDRequest request,
        io.grpc.stub.StreamObserver<EBIDResponse> responseObserver) {
      asyncUnimplementedUnaryCall(getGenerateEBIDMethod(), responseObserver);
    }

    /**
     */
    public void decryptEBID(DecryptEBIDRequest request,
        io.grpc.stub.StreamObserver<EBIDResponse> responseObserver) {
      asyncUnimplementedUnaryCall(getDecryptEBIDMethod(), responseObserver);
    }

    /**
     */
    public void encryptCountryCode(EncryptCountryCodeRequest request,
        io.grpc.stub.StreamObserver<EncryptCountryCodeResponse> responseObserver) {
      asyncUnimplementedUnaryCall(getEncryptCountryCodeMethod(), responseObserver);
    }

    /**
     */
    public void decryptCountryCode(DecryptCountryCodeRequest request,
        io.grpc.stub.StreamObserver<DecryptCountryCodeResponse> responseObserver) {
      asyncUnimplementedUnaryCall(getDecryptCountryCodeMethod(), responseObserver);
    }

    /**
     */
    public void generateMacHello(MacHelloGenerationRequest request,
        io.grpc.stub.StreamObserver<MacHelloGenerationResponse> responseObserver) {
      asyncUnimplementedUnaryCall(getGenerateMacHelloMethod(), responseObserver);
    }

    /**
     */
    public void validateMacHello(MacHelloValidationRequest request,
        io.grpc.stub.StreamObserver<MacValidationResponse> responseObserver) {
      asyncUnimplementedUnaryCall(getValidateMacHelloMethod(), responseObserver);
    }

    /**
     */
    public void validateMacEsr(MacEsrValidationRequest request,
        io.grpc.stub.StreamObserver<MacValidationResponse> responseObserver) {
      asyncUnimplementedUnaryCall(getValidateMacEsrMethod(), responseObserver);
    }

    /**
     */
    public void validateMacForType(MacValidationForTypeRequest request,
        io.grpc.stub.StreamObserver<MacValidationResponse> responseObserver) {
      asyncUnimplementedUnaryCall(getValidateMacForTypeMethod(), responseObserver);
    }

    @java.lang.Override public final io.grpc.ServerServiceDefinition bindService() {
      return io.grpc.ServerServiceDefinition.builder(getServiceDescriptor())
          .addMethod(
            getGenerateEphemeralTupleMethod(),
            asyncServerStreamingCall(
              new MethodHandlers<
                EphemeralTupleRequest,
                EphemeralTupleResponse>(
                  this, METHODID_GENERATE_EPHEMERAL_TUPLE)))
          .addMethod(
            getGenerateEBIDMethod(),
            asyncUnaryCall(
              new MethodHandlers<
                GenerateEBIDRequest,
                EBIDResponse>(
                  this, METHODID_GENERATE_EBID)))
          .addMethod(
            getDecryptEBIDMethod(),
            asyncUnaryCall(
              new MethodHandlers<
                DecryptEBIDRequest,
                EBIDResponse>(
                  this, METHODID_DECRYPT_EBID)))
          .addMethod(
            getEncryptCountryCodeMethod(),
            asyncUnaryCall(
              new MethodHandlers<
                EncryptCountryCodeRequest,
                EncryptCountryCodeResponse>(
                  this, METHODID_ENCRYPT_COUNTRY_CODE)))
          .addMethod(
            getDecryptCountryCodeMethod(),
            asyncUnaryCall(
              new MethodHandlers<
                DecryptCountryCodeRequest,
                DecryptCountryCodeResponse>(
                  this, METHODID_DECRYPT_COUNTRY_CODE)))
          .addMethod(
            getGenerateMacHelloMethod(),
            asyncUnaryCall(
              new MethodHandlers<
                MacHelloGenerationRequest,
                MacHelloGenerationResponse>(
                  this, METHODID_GENERATE_MAC_HELLO)))
          .addMethod(
            getValidateMacHelloMethod(),
            asyncUnaryCall(
              new MethodHandlers<
                MacHelloValidationRequest,
                MacValidationResponse>(
                  this, METHODID_VALIDATE_MAC_HELLO)))
          .addMethod(
            getValidateMacEsrMethod(),
            asyncUnaryCall(
              new MethodHandlers<
                MacEsrValidationRequest,
                MacValidationResponse>(
                  this, METHODID_VALIDATE_MAC_ESR)))
          .addMethod(
            getValidateMacForTypeMethod(),
            asyncUnaryCall(
              new MethodHandlers<
                MacValidationForTypeRequest,
                MacValidationResponse>(
                  this, METHODID_VALIDATE_MAC_FOR_TYPE)))
          .build();
    }
  }

  /**
   * <pre>
   * The greeting service definition.
   * </pre>
   */
  public static final class CryptoGrpcServiceImplStub extends io.grpc.stub.AbstractAsyncStub<CryptoGrpcServiceImplStub> {
    private CryptoGrpcServiceImplStub(
        io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
      super(channel, callOptions);
    }

    @java.lang.Override
    protected CryptoGrpcServiceImplStub build(
        io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
      return new CryptoGrpcServiceImplStub(channel, callOptions);
    }

    /**
     * <pre>
     * Streams a many greetings
     * </pre>
     */
    public void generateEphemeralTuple(EphemeralTupleRequest request,
        io.grpc.stub.StreamObserver<EphemeralTupleResponse> responseObserver) {
      asyncServerStreamingCall(
          getChannel().newCall(getGenerateEphemeralTupleMethod(), getCallOptions()), request, responseObserver);
    }

    /**
     */
    public void generateEBID(GenerateEBIDRequest request,
        io.grpc.stub.StreamObserver<EBIDResponse> responseObserver) {
      asyncUnaryCall(
          getChannel().newCall(getGenerateEBIDMethod(), getCallOptions()), request, responseObserver);
    }

    /**
     */
    public void decryptEBID(DecryptEBIDRequest request,
        io.grpc.stub.StreamObserver<EBIDResponse> responseObserver) {
      asyncUnaryCall(
          getChannel().newCall(getDecryptEBIDMethod(), getCallOptions()), request, responseObserver);
    }

    /**
     */
    public void encryptCountryCode(EncryptCountryCodeRequest request,
        io.grpc.stub.StreamObserver<EncryptCountryCodeResponse> responseObserver) {
      asyncUnaryCall(
          getChannel().newCall(getEncryptCountryCodeMethod(), getCallOptions()), request, responseObserver);
    }

    /**
     */
    public void decryptCountryCode(DecryptCountryCodeRequest request,
        io.grpc.stub.StreamObserver<DecryptCountryCodeResponse> responseObserver) {
      asyncUnaryCall(
          getChannel().newCall(getDecryptCountryCodeMethod(), getCallOptions()), request, responseObserver);
    }

    /**
     */
    public void generateMacHello(MacHelloGenerationRequest request,
        io.grpc.stub.StreamObserver<MacHelloGenerationResponse> responseObserver) {
      asyncUnaryCall(
          getChannel().newCall(getGenerateMacHelloMethod(), getCallOptions()), request, responseObserver);
    }

    /**
     */
    public void validateMacHello(MacHelloValidationRequest request,
        io.grpc.stub.StreamObserver<MacValidationResponse> responseObserver) {
      asyncUnaryCall(
          getChannel().newCall(getValidateMacHelloMethod(), getCallOptions()), request, responseObserver);
    }

    /**
     */
    public void validateMacEsr(MacEsrValidationRequest request,
        io.grpc.stub.StreamObserver<MacValidationResponse> responseObserver) {
      asyncUnaryCall(
          getChannel().newCall(getValidateMacEsrMethod(), getCallOptions()), request, responseObserver);
    }

    /**
     */
    public void validateMacForType(MacValidationForTypeRequest request,
        io.grpc.stub.StreamObserver<MacValidationResponse> responseObserver) {
      asyncUnaryCall(
          getChannel().newCall(getValidateMacForTypeMethod(), getCallOptions()), request, responseObserver);
    }
  }

  /**
   * <pre>
   * The greeting service definition.
   * </pre>
   */
  public static final class CryptoGrpcServiceImplBlockingStub extends io.grpc.stub.AbstractBlockingStub<CryptoGrpcServiceImplBlockingStub> {
    private CryptoGrpcServiceImplBlockingStub(
        io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
      super(channel, callOptions);
    }

    @java.lang.Override
    protected CryptoGrpcServiceImplBlockingStub build(
        io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
      return new CryptoGrpcServiceImplBlockingStub(channel, callOptions);
    }

    /**
     * <pre>
     * Streams a many greetings
     * </pre>
     */
    public java.util.Iterator<EphemeralTupleResponse> generateEphemeralTuple(
        EphemeralTupleRequest request) {
      return blockingServerStreamingCall(
          getChannel(), getGenerateEphemeralTupleMethod(), getCallOptions(), request);
    }

    /**
     */
    public EBIDResponse generateEBID(GenerateEBIDRequest request) {
      return blockingUnaryCall(
          getChannel(), getGenerateEBIDMethod(), getCallOptions(), request);
    }

    /**
     */
    public EBIDResponse decryptEBID(DecryptEBIDRequest request) {
      return blockingUnaryCall(
          getChannel(), getDecryptEBIDMethod(), getCallOptions(), request);
    }

    /**
     */
    public EncryptCountryCodeResponse encryptCountryCode(EncryptCountryCodeRequest request) {
      return blockingUnaryCall(
          getChannel(), getEncryptCountryCodeMethod(), getCallOptions(), request);
    }

    /**
     */
    public DecryptCountryCodeResponse decryptCountryCode(DecryptCountryCodeRequest request) {
      return blockingUnaryCall(
          getChannel(), getDecryptCountryCodeMethod(), getCallOptions(), request);
    }

    /**
     */
    public MacHelloGenerationResponse generateMacHello(MacHelloGenerationRequest request) {
      return blockingUnaryCall(
          getChannel(), getGenerateMacHelloMethod(), getCallOptions(), request);
    }

    /**
     */
    public MacValidationResponse validateMacHello(MacHelloValidationRequest request) {
      return blockingUnaryCall(
          getChannel(), getValidateMacHelloMethod(), getCallOptions(), request);
    }

    /**
     */
    public MacValidationResponse validateMacEsr(MacEsrValidationRequest request) {
      return blockingUnaryCall(
          getChannel(), getValidateMacEsrMethod(), getCallOptions(), request);
    }

    /**
     */
    public MacValidationResponse validateMacForType(MacValidationForTypeRequest request) {
      return blockingUnaryCall(
          getChannel(), getValidateMacForTypeMethod(), getCallOptions(), request);
    }
  }

  /**
   * <pre>
   * The greeting service definition.
   * </pre>
   */
  public static final class CryptoGrpcServiceImplFutureStub extends io.grpc.stub.AbstractFutureStub<CryptoGrpcServiceImplFutureStub> {
    private CryptoGrpcServiceImplFutureStub(
        io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
      super(channel, callOptions);
    }

    @java.lang.Override
    protected CryptoGrpcServiceImplFutureStub build(
        io.grpc.Channel channel, io.grpc.CallOptions callOptions) {
      return new CryptoGrpcServiceImplFutureStub(channel, callOptions);
    }

    /**
     */
    public com.google.common.util.concurrent.ListenableFuture<EBIDResponse> generateEBID(
        GenerateEBIDRequest request) {
      return futureUnaryCall(
          getChannel().newCall(getGenerateEBIDMethod(), getCallOptions()), request);
    }

    /**
     */
    public com.google.common.util.concurrent.ListenableFuture<EBIDResponse> decryptEBID(
        DecryptEBIDRequest request) {
      return futureUnaryCall(
          getChannel().newCall(getDecryptEBIDMethod(), getCallOptions()), request);
    }

    /**
     */
    public com.google.common.util.concurrent.ListenableFuture<EncryptCountryCodeResponse> encryptCountryCode(
        EncryptCountryCodeRequest request) {
      return futureUnaryCall(
          getChannel().newCall(getEncryptCountryCodeMethod(), getCallOptions()), request);
    }

    /**
     */
    public com.google.common.util.concurrent.ListenableFuture<DecryptCountryCodeResponse> decryptCountryCode(
        DecryptCountryCodeRequest request) {
      return futureUnaryCall(
          getChannel().newCall(getDecryptCountryCodeMethod(), getCallOptions()), request);
    }

    /**
     */
    public com.google.common.util.concurrent.ListenableFuture<MacHelloGenerationResponse> generateMacHello(
        MacHelloGenerationRequest request) {
      return futureUnaryCall(
          getChannel().newCall(getGenerateMacHelloMethod(), getCallOptions()), request);
    }

    /**
     */
    public com.google.common.util.concurrent.ListenableFuture<MacValidationResponse> validateMacHello(
        MacHelloValidationRequest request) {
      return futureUnaryCall(
          getChannel().newCall(getValidateMacHelloMethod(), getCallOptions()), request);
    }

    /**
     */
    public com.google.common.util.concurrent.ListenableFuture<MacValidationResponse> validateMacEsr(
        MacEsrValidationRequest request) {
      return futureUnaryCall(
          getChannel().newCall(getValidateMacEsrMethod(), getCallOptions()), request);
    }

    /**
     */
    public com.google.common.util.concurrent.ListenableFuture<MacValidationResponse> validateMacForType(
        MacValidationForTypeRequest request) {
      return futureUnaryCall(
          getChannel().newCall(getValidateMacForTypeMethod(), getCallOptions()), request);
    }
  }

  private static final int METHODID_GENERATE_EPHEMERAL_TUPLE = 0;
  private static final int METHODID_GENERATE_EBID = 1;
  private static final int METHODID_DECRYPT_EBID = 2;
  private static final int METHODID_ENCRYPT_COUNTRY_CODE = 3;
  private static final int METHODID_DECRYPT_COUNTRY_CODE = 4;
  private static final int METHODID_GENERATE_MAC_HELLO = 5;
  private static final int METHODID_VALIDATE_MAC_HELLO = 6;
  private static final int METHODID_VALIDATE_MAC_ESR = 7;
  private static final int METHODID_VALIDATE_MAC_FOR_TYPE = 8;

  private static final class MethodHandlers<Req, Resp> implements
      io.grpc.stub.ServerCalls.UnaryMethod<Req, Resp>,
      io.grpc.stub.ServerCalls.ServerStreamingMethod<Req, Resp>,
      io.grpc.stub.ServerCalls.ClientStreamingMethod<Req, Resp>,
      io.grpc.stub.ServerCalls.BidiStreamingMethod<Req, Resp> {
    private final CryptoGrpcServiceImplImplBase serviceImpl;
    private final int methodId;

    MethodHandlers(CryptoGrpcServiceImplImplBase serviceImpl, int methodId) {
      this.serviceImpl = serviceImpl;
      this.methodId = methodId;
    }

    @java.lang.Override
    @java.lang.SuppressWarnings("unchecked")
    public void invoke(Req request, io.grpc.stub.StreamObserver<Resp> responseObserver) {
      switch (methodId) {
        case METHODID_GENERATE_EPHEMERAL_TUPLE:
          serviceImpl.generateEphemeralTuple((EphemeralTupleRequest) request,
              (io.grpc.stub.StreamObserver<EphemeralTupleResponse>) responseObserver);
          break;
        case METHODID_GENERATE_EBID:
          serviceImpl.generateEBID((GenerateEBIDRequest) request,
              (io.grpc.stub.StreamObserver<EBIDResponse>) responseObserver);
          break;
        case METHODID_DECRYPT_EBID:
          serviceImpl.decryptEBID((DecryptEBIDRequest) request,
              (io.grpc.stub.StreamObserver<EBIDResponse>) responseObserver);
          break;
        case METHODID_ENCRYPT_COUNTRY_CODE:
          serviceImpl.encryptCountryCode((EncryptCountryCodeRequest) request,
              (io.grpc.stub.StreamObserver<EncryptCountryCodeResponse>) responseObserver);
          break;
        case METHODID_DECRYPT_COUNTRY_CODE:
          serviceImpl.decryptCountryCode((DecryptCountryCodeRequest) request,
              (io.grpc.stub.StreamObserver<DecryptCountryCodeResponse>) responseObserver);
          break;
        case METHODID_GENERATE_MAC_HELLO:
          serviceImpl.generateMacHello((MacHelloGenerationRequest) request,
              (io.grpc.stub.StreamObserver<MacHelloGenerationResponse>) responseObserver);
          break;
        case METHODID_VALIDATE_MAC_HELLO:
          serviceImpl.validateMacHello((MacHelloValidationRequest) request,
              (io.grpc.stub.StreamObserver<MacValidationResponse>) responseObserver);
          break;
        case METHODID_VALIDATE_MAC_ESR:
          serviceImpl.validateMacEsr((MacEsrValidationRequest) request,
              (io.grpc.stub.StreamObserver<MacValidationResponse>) responseObserver);
          break;
        case METHODID_VALIDATE_MAC_FOR_TYPE:
          serviceImpl.validateMacForType((MacValidationForTypeRequest) request,
              (io.grpc.stub.StreamObserver<MacValidationResponse>) responseObserver);
          break;
        default:
          throw new AssertionError();
      }
    }

    @java.lang.Override
    @java.lang.SuppressWarnings("unchecked")
    public io.grpc.stub.StreamObserver<Req> invoke(
        io.grpc.stub.StreamObserver<Resp> responseObserver) {
      switch (methodId) {
        default:
          throw new AssertionError();
      }
    }
  }

  private static abstract class CryptoGrpcServiceImplBaseDescriptorSupplier
      implements io.grpc.protobuf.ProtoFileDescriptorSupplier, io.grpc.protobuf.ProtoServiceDescriptorSupplier {
    CryptoGrpcServiceImplBaseDescriptorSupplier() {}

    @java.lang.Override
    public com.google.protobuf.Descriptors.FileDescriptor getFileDescriptor() {
      return CryptoGrpcService.getDescriptor();
    }

    @java.lang.Override
    public com.google.protobuf.Descriptors.ServiceDescriptor getServiceDescriptor() {
      return getFileDescriptor().findServiceByName("CryptoGrpcServiceImpl");
    }
  }

  private static final class CryptoGrpcServiceImplFileDescriptorSupplier
      extends CryptoGrpcServiceImplBaseDescriptorSupplier {
    CryptoGrpcServiceImplFileDescriptorSupplier() {}
  }

  private static final class CryptoGrpcServiceImplMethodDescriptorSupplier
      extends CryptoGrpcServiceImplBaseDescriptorSupplier
      implements io.grpc.protobuf.ProtoMethodDescriptorSupplier {
    private final String methodName;

    CryptoGrpcServiceImplMethodDescriptorSupplier(String methodName) {
      this.methodName = methodName;
    }

    @java.lang.Override
    public com.google.protobuf.Descriptors.MethodDescriptor getMethodDescriptor() {
      return getServiceDescriptor().findMethodByName(methodName);
    }
  }

  private static volatile io.grpc.ServiceDescriptor serviceDescriptor;

  public static io.grpc.ServiceDescriptor getServiceDescriptor() {
    io.grpc.ServiceDescriptor result = serviceDescriptor;
    if (result == null) {
      synchronized (CryptoGrpcServiceImplGrpc.class) {
        result = serviceDescriptor;
        if (result == null) {
          serviceDescriptor = result = io.grpc.ServiceDescriptor.newBuilder(SERVICE_NAME)
              .setSchemaDescriptor(new CryptoGrpcServiceImplFileDescriptorSupplier())
              .addMethod(getGenerateEphemeralTupleMethod())
              .addMethod(getGenerateEBIDMethod())
              .addMethod(getDecryptEBIDMethod())
              .addMethod(getEncryptCountryCodeMethod())
              .addMethod(getDecryptCountryCodeMethod())
              .addMethod(getGenerateMacHelloMethod())
              .addMethod(getValidateMacHelloMethod())
              .addMethod(getValidateMacEsrMethod())
              .addMethod(getValidateMacForTypeMethod())
              .build();
        }
      }
    }
    return result;
  }
}
