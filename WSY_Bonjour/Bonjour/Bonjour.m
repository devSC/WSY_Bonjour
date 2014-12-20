//
//  Bonjour.m
//  WSY_Bonjour
//
//  Created by 袁仕崇 on 14/12/20.
//  Copyright (c) 2014年 wilson-yuan. All rights reserved.
//

//__bridge只做类型转换，但是不修改对象（内存）管理权；

//__bridge_retained（也可以使用CFBridgingRetain）将Objective-C的对象转换为Core Foundation的对象，同时将对象（内存）的管理权交给我们，后续需要使用CFRelease或者相关方法来释放对象；

//__bridge_transfer（也可以使用CFBridgingRelease）将Core Foundation的对象转换为Objective-C的对象，同时将对象（内存）的管理权交给ARC。


#import "Bonjour.h"
#import <netinet/in.h>
#import <sys/socket.h>
#import "Utils.h"
#import "HelpRequest.h"

@interface Bonjour () <NSStreamDelegate, NSNetServiceDelegate>
{
    NSNetService *_service;
    NSInputStream *_inputStream;
    NSOutputStream *_outputStream;
    
    NSMutableData *_receiveData;
    NSMutableData *_sendData;
    
    NSNumber *_bytesRead;
    NSNumber *_bytesWritten;
    
    uint16_t port;
    
    CFSocketRef _ipv4Socket;
    CFSocketRef _ipv6Socket;
}

@end
@implementation Bonjour

#pragma mark - Lifecycle
+ (Bonjour *)defaultBonjour
{
    static Bonjour *_instance = nil;
    if (!_instance) {
        _instance = [[self alloc] init];
    }
    return _instance;
}
#pragma mark - Methods
- (BOOL)publishServiceWithName:(NSString *)name
{
    /**
     *  setup the listening socket for connection attempts and determine a port
     *on which to advertise the service
     */
    if (![self setupListeningSocket]) {
        return NO;
    }
    
    //creat the service for publishing
    //the type should be registered -iana.org
    _service = [[NSNetService alloc] initWithDomain:@"" type:@"_associateHelp._tcp." name:name port:port];
    if (_service == nil) {
        return NO;
    }
    _service.delegate = self;
    
    //publish service
    [Utils postNotifification:kPublishBonjourStartNotification];
    [_service publish];
    
    return YES;
}
- (void)stopService {
    [_service stop];
}

- (void)sendHelpResponse:(HelpResponse*)response {
    if (_sendData == nil) {
        _sendData = [[NSMutableData alloc] init];
    }
    NSData *responseData =
    [NSKeyedArchiver archivedDataWithRootObject:response];
    
    [_sendData appendData:responseData];
    [_outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                            forMode:NSDefaultRunLoopMode];
    
    // associate is going to help customer
    // stop the service so they aren't discoverable
    // while with the customer
    if (response.response == YES) {
        [self stopService];
    }
}

#pragma mark - NSNetServiceDelegate
- (void)netServiceDidPublish:(NSNetService *)sender {
    [Utils postNotifification:kPublishBonjourSuccessNotification];
}

- (void)netService:(NSNetService *)sender
     didNotPublish:(NSDictionary *)errorDict {
    // typically you would pass along the errorDict
    // object or some form of error messaging
    [Utils postNotifification:kPublishBonjourErrorNotification];
}

- (void)netServiceDidStop:(NSNetService *)sender {
    // reset port so a new one is assigned
    port = 0;
    CFRelease(_ipv4Socket);
    CFRelease(_ipv6Socket);
    
    [Utils postNotifification:kStopBonjourSuccessNotification];
}
#pragma mark - NSStreamDelegate
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    switch (eventCode) {
        case NSStreamEventHasBytesAvailable:{
            if (aStream == _inputStream) {
                if (_receiveData == nil) {
                    _receiveData = [[NSMutableData alloc] init];
                }
                uint8_t buffer[1024];
                unsigned int len = 0;
                len = [(NSInputStream *)aStream read:buffer maxLength:1024];
                if (len) {
                    [_receiveData appendBytes:(const void *)buffer length:len];
                    _bytesRead = [NSNumber numberWithInt:([_bytesRead intValue] + len)];
                    
                    if (![_inputStream hasBytesAvailable]) {
                        //you could optionally keep the 'transaction'
                        //state stored so that you could determine
                        //which object you have expecting
                        HelpRequest *request;
                        @try {
                            request = [NSKeyedUnarchiver unarchiveObjectWithData: _receiveData];
                            
                            NSDictionary *info = [NSDictionary dictionaryWithObject:request forKey:kNotificationResultSet];
                            [[NSNotificationCenter defaultCenter]
                             postNotificationName:
                             kHelpRequestedNotification
                             object:nil
                             userInfo:info];
                            
                        }
                        @catch (NSException *exception) {
                            NSString *msg = @"Exception while unarchiving request data";
                            NSLog(@"%@", msg);
                        }
                        @finally {
                            //clean up
                            _receiveData = nil;
                            _bytesRead = nil;
                        }
                        
                    }
                }else {
                    NSLog(@"No data found in buffer");
                }
            }
        }break;
        case NSStreamEventHasSpaceAvailable: {
            if (aStream == _outputStream) {
                //send data if there is some pending
                if ([_sendData length] > 0) {
                    uint8_t *readBytes = (uint8_t *)[_sendData mutableBytes];
                    
                    //keep track of pointer position
                    readBytes += [_bytesWritten intValue];
                    int data_len = [_sendData length];
                    
                    unsigned int len = ((data_len - [_bytesWritten intValue] >= 1024) ? 1024 : (data_len - [_bytesWritten intValue]));
                    uint8_t buffer[len];
                    (void)memcpy(buffer, readBytes, len);
                    
                    len = [(NSOutputStream*)aStream
                           write:(const uint8_t *)buffer
                           maxLength:len];
                    
                    _bytesWritten =
                    [NSNumber
                     numberWithInt:([_bytesWritten intValue]+len)];
                    
                    if ([_sendData length] == [_bytesWritten intValue]) {
                        _sendData = nil;
                        [_outputStream
                         removeFromRunLoop:[NSRunLoop currentRunLoop]
                         forMode:NSDefaultRunLoopMode];
                    }
                    
                    if ([_bytesWritten intValue] == -1) {
                        NSLog(@"Error writing data.");
                    }
                }
            }
        }break;
        case NSStreamEventOpenCompleted:
            if (aStream == _inputStream) {
                NSLog(@"Input Stream Opened");
            } else {
                NSLog(@"Output Stream Opened");
            }
            break;
            
        case NSStreamEventEndEncountered: {
            [aStream close];
            [aStream removeFromRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSDefaultRunLoopMode];
            break;
        }
            
        case NSStreamEventErrorOccurred:
            if (aStream == _inputStream) {
                NSLog(@"Input error: %@", [aStream streamError]);
            } else {
                NSLog(@"Output error: %@", [aStream streamError]);
            }
            break;
            
        default:
            if (aStream == _inputStream) {
                NSLog(@"Input default error: %@", [aStream streamError]);
            } else {
                NSLog(@"Output default error: %@", [aStream streamError]);
            }
        break;    }

}


//让系统为服务分配可用端口,并注册socket回调来监听连接请求
- (BOOL)setupListeningSocket
{
#if 0
    {
        // adapted from: Cocoa Echo application on developer portal. example is available at
        // https://developer.apple.com/library/mac/#samplecode/CocoaEcho/Introduction/Intro.html#//apple_ref/doc/uid/DTS10003603-Intro-DontLinkElementID_2
        CFSocketContext socketCtxt = {0, (__bridge void*)self, NULL, NULL, NULL};
        _ipv4Socket = CFSocketCreate(kCFAllocatorDefault,
                                    PF_INET,
                                    SOCK_STREAM,
                                    IPPROTO_TCP,
                                    kCFSocketAcceptCallBack,
                                    (CFSocketCallBack)&BonjourServerAcceptCallBack,
                                    &socketCtxt);
        
        ipv6socket = CFSocketCreate(kCFAllocatorDefault,
                                    PF_INET6,
                                    SOCK_STREAM,
                                    IPPROTO_TCP,
                                    kCFSocketAcceptCallBack,
                                    (CFSocketCallBack)&BonjourServerAcceptCallBack,
                                    &socketCtxt);
        
        if (ipv4socket == NULL || ipv6socket == NULL) {
            if (ipv4socket) CFRelease(ipv4socket);
            if (ipv6socket) CFRelease(ipv6socket);
            ipv4socket = NULL;
            ipv6socket = NULL;
            return NO;
        }
        
        int yes = 1;
        setsockopt(CFSocketGetNative(ipv4socket),
                   SOL_SOCKET,
                   SO_REUSEADDR,
                   (void *)&yes,
                   sizeof(yes));
        
        setsockopt(CFSocketGetNative(ipv6socket),
                   SOL_SOCKET,
                   SO_REUSEADDR,
                   (void *)&yes,
                   sizeof(yes));
        
        // set up the IPv4 address
        // if port is 0, causes the kernel to choose a port
        struct sockaddr_in addr4;
        memset(&addr4, 0, sizeof(addr4));
        addr4.sin_len = sizeof(addr4);
        addr4.sin_family = AF_INET;
        addr4.sin_port = htons(port);
        addr4.sin_addr.s_addr = htonl(INADDR_ANY);
        NSData *address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
        
        if (kCFSocketSuccess != CFSocketSetAddress(ipv4socket,
                                                   (__bridge CFDataRef)address4)) {
            
            NSLog(@"Error setting ipv4 socket address");
            if (ipv4socket) CFRelease(ipv4socket);
            if (ipv6socket) CFRelease(ipv6socket);
            ipv4socket = NULL;
            ipv6socket = NULL;
            return NO;
        }
        
        if (port == 0) {
            // get the port number, port will be used for IPv6 address and service
            NSData *addr = (__bridge NSData *)CFSocketCopyAddress(ipv4socket);
            memcpy(&addr4, [addr bytes], [addr length]);
            port = ntohs(addr4.sin_port);
        }
        
        // set up the IPv6 address
        struct sockaddr_in6 addr6;
        memset(&addr6, 0, sizeof(addr6));
        addr6.sin6_len = sizeof(addr6);
        addr6.sin6_family = AF_INET6;
        addr6.sin6_port = htons(port);
        memcpy(&(addr6.sin6_addr), &in6addr_any, sizeof(addr6.sin6_addr));
        NSData *address6 = [NSData dataWithBytes:&addr6 length:sizeof(addr6)];
        
        if (kCFSocketSuccess != CFSocketSetAddress(ipv6socket,
                                                   (__bridge CFDataRef)address6)) {
            
            NSLog(@"Error setting ipv6 socket address");
            if (ipv4socket) CFRelease(ipv4socket);
            if (ipv6socket) CFRelease(ipv6socket);
            ipv4socket = NULL;
            ipv6socket = NULL;
            return NO;
        }
        
        // set up sources and add sockets to run loop
        CFRunLoopRef cfrl = CFRunLoopGetCurrent();
        CFRunLoopSourceRef src4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault,
                                                              ipv4socket,
                                                              0);
        
        CFRunLoopAddSource(cfrl, src4, kCFRunLoopCommonModes);
        CFRelease(src4);
        
        CFRunLoopSourceRef src6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault,
                                                              ipv6socket,
                                                              0);
        
        CFRunLoopAddSource(cfrl, src6, kCFRunLoopCommonModes);
        CFRelease(src6);
        return YES;
    }
#else
    // adapted from: Cocoa Echo application on developer portal. example is available at
    // https://developer.apple.com/library/mac/#samplecode/CocoaEcho/Introduction/Intro.html#//apple_ref/doc/uid/DTS10003603-Intro-DontLinkElementID_2
    //结构体
    CFSocketContext socketCtxt = {0, (__bridge void *)self, NULL,NULL,NULL};
    
    _ipv4Socket = CFSocketCreate(kCFAllocatorDefault,
                                 PF_INET,
                                 SOCK_STREAM,
                                 IPPROTO_TCP,
                                 kCFSocketAcceptCallBack,
                                 (CFSocketCallBack)&BonjourServerAcceptCallBack,
                                 &socketCtxt);
    
    _ipv6Socket = CFSocketCreate(kCFAllocatorDefault,
                                 PF_INET6, SOCK_STREAM,
                                 IPPROTO_TCP,
                                 kCFSocketAcceptCallBack,
                                 (CFSocketCallBack)& BonjourServerAcceptCallBack,
                                 &socketCtxt);
    
    if (_ipv4Socket == NULL || _ipv6Socket == NULL) {
        if (_ipv6Socket) {
            CFRelease(_ipv6Socket);
        }
        if (_ipv4Socket) {
            CFRelease(_ipv4Socket);
        }
        _ipv4Socket = NULL;
        _ipv6Socket = NULL;
        return NO;
    }
    
    int yes = 1;
    
    setsockopt(CFSocketGetNative(_ipv4Socket),
               SOL_SOCKET,
               SO_REUSEADDR,
               (void *)&yes,
               sizeof(yes));
    
    setsockopt(CFSocketGetNative(_ipv6Socket),
               SOL_SOCKET,
               SO_REUSEADDR,
               (void *)&yes,
               sizeof(yes));
    //setup the IPV4 address
    //if port is 0, causes the kernel to choose a port
    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(port);
    
    addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    NSData *address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
    
    if (kCFSocketSuccess != CFSocketSetAddress(_ipv4Socket, (__bridge CFDataRef)address4)) {
        
        NSLog(@"Error setting ipv4 socket address");
        if (_ipv4Socket) {
            CFRelease(_ipv4Socket);
        }
        if (_ipv6Socket) {
            CFRelease(_ipv6Socket);
        }
        _ipv4Socket = NULL;
        _ipv6Socket = NULL;
        return NO;
    }
    if (port == 0) {
        NSData *addr = (__bridge NSData *)CFSocketCopyAddress(_ipv4Socket);
        memcpy(&addr4, [addr bytes], [addr length]);
        port = ntohs(addr4.sin_port);
    }
    
    //setup the IPV6 address
    struct sockaddr_in6 addr6;
    memset(&addr6, 0, sizeof(addr6));
    addr6.sin6_len = sizeof(addr6);
    addr6.sin6_family = AF_INET6;
    addr6.sin6_port = htons(port);
    memcpy(&(addr6.sin6_addr), &in6addr_any, sizeof(addr6.sin6_addr));
    
    NSData *address6 = [NSData dataWithBytes:&addr6 length:sizeof(addr6)];
    
    if (kCFSocketSuccess != CFSocketSetAddress(_ipv6Socket, (__bridge CFDataRef)address6)) {
        NSLog(@"Error setting ipv6 socket address");
        if (_ipv4Socket) {
            CFRelease(_ipv4Socket);
        }
        if (_ipv6Socket) {
            CFRelease(_ipv6Socket);
        }
        _ipv4Socket = NULL;
        _ipv6Socket = NULL;
        return NO;
              
    }
    
    //setup sources and add socket to run loop
    CFRunLoopRef cfrl = CFRunLoopGetCurrent();
    CFRunLoopSourceRef src4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4Socket, 0);
    CFRunLoopAddSource(cfrl, src4, kCFRunLoopCommonModes);
    CFRelease(src4);
    
    CFRunLoopSourceRef src6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv6Socket, 0);
    CFRunLoopAddSource(cfrl, src6, kCFRunLoopCommonModes);
    CFRelease(src6);
    
    return YES;
#endif
}
- (void)handleNewConnectionWithInputStream: (NSInputStream *)ipsr outputStream: (NSOutputStream *)opsr
{
    _inputStream = ipsr;
    _outputStream = opsr;
    
    _inputStream.delegate = self;
    _outputStream.delegate = self;
    
    [_inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    //output stream is scheduled in the runloop when it is needed
    
    if (_inputStream.streamStatus == NSStreamStatusNotOpen) {
        [_inputStream open];
    }
    if (_outputStream.streamStatus == NSStreamStatusNotOpen) {
        [_outputStream open];
    }
    
}
static void BonjourServerAcceptCallBack (CFSocketRef socket,
                                         CFSocketCallBackType type,
                                         CFDataRef address,
                                         const void *data,
                                         void *info){
    Bonjour *server = (__bridge Bonjour *)info;
    if (type == kCFSocketAcceptCallBack) {
        //AcceptCallBack:data is pointer to a CFSocketNativeHandle
        CFSocketNativeHandle socketHandle = *(CFSocketNativeHandle *)data;
        
        CFReadStreamRef readStream = NULL;
        CFWriteStreamRef writeStrem = NULL;
        CFStreamCreatePairWithSocket(kCFAllocatorDefault,
                                     socketHandle,
                                     &readStream,
                                     &writeStrem);
        if (readStream && writeStrem){
            CFReadStreamSetProperty(readStream,
                                    kCFStreamPropertyShouldCloseNativeSocket,
                                    kCFBooleanTrue);
        CFWriteStreamSetProperty(writeStrem,
                                 kCFStreamPropertyShouldCloseNativeSocket,
                                 kCFBooleanTrue);
        
        NSInputStream *is = (__bridge NSInputStream *)readStream;
        NSOutputStream *os = (__bridge NSOutputStream *)writeStrem;
        [server handleNewConnectionWithInputStream:is outputStream:os];
        }else{
            //encountered  failure
            //no need for socket anymore
            close(socketHandle);
        }
        
        //clean up
        if (readStream) {
            CFRelease(readStream);
        }
        if (writeStrem) {
            CFRelease(writeStrem);
        }
    }
}
@end
