//
//  MeshPipe.m
//  MeshPipe
//
//  Created by Nevyn Bengtsson on 2015-08-18.
//  Copyright © 2015 ThirdCog. All rights reserved.
//

#import "MeshPipe.h"
#import "GCDAsyncUdpSocket.h"
#import <GZIP/GZIP.h>
#include <netinet/in.h>
#include <arpa/inet.h>
static NSString *MeshPipeLocalHost = @"localhost";

#ifdef DEBUG
    #define MPLogDebug(...) NSLog(__VA_ARGS__)
#else
    #define MPLogDebug(...)
#endif
#define MPLogError(...) NSLog(__VA_ARGS__)

typedef NS_ENUM(uint8_t, _MeshPipeMessageType) {
	_MeshPipeMessageTypeInternal = 1,
	_MeshPipeMessageTypeData = 2,
};

@interface MeshPipe () <GCDAsyncUdpSocketDelegate>
{
	NSMutableSet<MeshPipePeer*> *_peers;
	NSMutableArray<MeshPipePeer*> *_potentialPeers;
	int _myPort;
	NSTimer *_keepaliveTimer;
}
@property(nonatomic,readonly) GCDAsyncUdpSocket *listenSocket;
@end

@interface MeshPipePeer ()
{
}
@property(nonatomic) int port;
@property(nonatomic,readwrite) NSString *name;
@property(nonatomic) GCDAsyncUdpSocket *socket;
@property(nonatomic) NSTimer *expectKeepaliveTimer;
@property(nonatomic,weak) MeshPipe *parent;
- (void)sendInternal:(NSDictionary*)internal;
@end

@interface MeshPipeSelfPeer : MeshPipePeer
@end

static const NSTimeInterval kKeepaliveDuration = 5;
static const NSTimeInterval kKeepaliveExpectedWithin = kKeepaliveDuration*1.5;

static NSData *SerializeInternal(NSDictionary *internal);
static NSDictionary *DeserializeInternal(NSData *data);

///// ------ IMPL --------

@implementation MeshPipe

- (instancetype)initWithBasePort:(int)basePort count:(int)count peerName:(NSString*)peerName delegate:(id<MeshPipeDelegate>)delegate
{
	if(!(self = [super init]))
		return nil;
	
	_basePort = basePort;
	_count = count;
	_peerName = peerName;
	_delegate = delegate;
	
	_potentialPeers = [NSMutableArray new];
	_peers = [NSMutableSet new];
	
	_listenSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self
                                                  delegateQueue:dispatch_get_main_queue()];
	for(int i = 0; i < count; i++) {
		int port = _basePort + i;
		BOOL success = [_listenSocket bindToPort:port error:NULL];
		if(success) {
			_myPort = port;
			break;
		}
	}
	if(!_myPort) {
		MPLogError(@"No free MeshPipe slots, not creating pipe");
		return nil;
	}
	
	MPLogDebug(@"MeshPipe listening on %d", _myPort);
	
    [_listenSocket beginReceiving:NULL];
    
	for(int i = 0; i < count; i++) {
		int port = _basePort + i;
		MeshPipePeer *potentialPeer = (port == _myPort) ? [MeshPipeSelfPeer new] : [MeshPipePeer new];
		potentialPeer.parent = self;
		potentialPeer.socket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self
                                                             delegateQueue:dispatch_get_main_queue()];
		potentialPeer.port = port;
		[_potentialPeers addObject:potentialPeer];
		
		NSError *err;
        if(![potentialPeer.socket connectToHost:MeshPipeLocalHost onPort:potentialPeer.port error:&err]) {
			MPLogError(@"Unexectedly couldn't connect to MeshPipe potential peer %d, giving up: %@", i, err);
			return nil;
		}
		[self announceTo:potentialPeer];
		[potentialPeer sendInternal:@{
			@"cmd": @"pleaseAnnounceTo",
		}];
	}
	
	_keepaliveTimer = [NSTimer scheduledTimerWithTimeInterval:kKeepaliveDuration target:self selector:@selector(keepalive) userInfo:nil repeats:YES];
	
	return self;
}

- (void)dealloc
{

}

- (void)disconnect
{
	MPLogDebug(@"Disconnecting from %@", _peers);
	for(MeshPipePeer *peer in _peers)
		[peer sendInternal:@{
			@"cmd": @"disconnected",
		}];
	[_keepaliveTimer invalidate];
	[_listenSocket closeAfterSending];
}

- (void)keepalive
{
	if(_peers.count == 0)
		return;
	
	MPLogDebug(@"Sending keepalive to %@", _peers);
	for(MeshPipePeer *peer in _peers) {
		[peer sendInternal:@{
			@"cmd": @"keepalive",
		}];
	}
}
- (void)keepaliveExpected:(NSTimer*)timer
{
	MeshPipePeer *peer = timer.userInfo;
	MPLogDebug(@"%@ timed out", peer);
	
	[peer sendInternal:@{
		@"cmd": @"youTimedOut"
	}];
	[self markPeerAsUnavailable:peer forReason:[NSError errorWithDomain:MeshPipeErrorDomain code:MeshPipeErrorPeerTimedOut userInfo:@{
		NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ timed out", peer.name],
	}]];
}

- (void)announceTo:(MeshPipePeer*)peer
{
	[peer sendInternal:@{
		@"cmd": @"announce",
		@"name": _peerName,
	}];
}

+ (NSArray <NSString *> *)_localHosts
{
    static NSArray <NSString *> *sLocalHosts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sLocalHosts = @[
                        MeshPipeLocalHost,
                        @"127.0.0.1",   // IPv4 loopback
                        @"::1",         // IPv6 loopback
                        ];
    });
    return sLocalHosts;
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock
   didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    NSString *host = [GCDAsyncUdpSocket hostFromAddress:address];
    UInt16 port = [GCDAsyncUdpSocket portFromAddress:address];

	if(![[MeshPipe _localHosts] containsObject:host]) {
		MPLogDebug(@"Received unexpected message from host %@", host);
		return;
	}
	
	if(port < _basePort || port >= _basePort + _count) {
		MPLogDebug(@"Received unexpected message on port %d", port);
		return;
	}
	int i = port - _basePort;
	
	MeshPipePeer *peer = _potentialPeers[i];
	
	_MeshPipeMessageType type = ((uint8_t*)[data bytes])[0];
	NSData *payload = [data subdataWithRange:NSMakeRange(1, data.length-1)];
	if(type == _MeshPipeMessageTypeInternal) {
		NSDictionary *internal = DeserializeInternal(payload);
		if(!internal) {
			MPLogDebug(@"Unable to deserialize %@", payload);
			return;
		}
		if(![self handleInternal:internal fromPeer:peer])
			return;
	} else if(type == _MeshPipeMessageTypeData) {
		MPLogDebug(@"Reveived from peer %@ message %@", peer, payload);
		if([self.delegate respondsToSelector:@selector(meshPipe:receivedData:fromPeer:)]) {
			[self.delegate meshPipe:self receivedData:payload fromPeer:peer];
		}
		if([peer.delegate respondsToSelector:@selector(meshPipePeer:receivedData:)]) {
			[peer.delegate meshPipePeer:peer receivedData:payload];
		}
	} else {
		MPLogDebug(@"Received unexpected message type from %@", peer);
		return;
	}
}

- (BOOL)handleInternal:(NSDictionary*)internal fromPeer:(MeshPipePeer*)peer
{
	MPLogDebug(@"Handling peer %@ internal %@", peer, internal);
	
	NSString *cmd = internal[@"cmd"];
	if(!cmd) return NO;
	
	if([cmd isEqual:@"pleaseAnnounceTo"]) {
		[self announceTo:peer];
	} else if([cmd isEqual:@"announce"]) {
		NSString *name = internal[@"name"];
		if(!name) return NO;
		peer.name = name;
		[self markPeerAsAvailable:peer];
	} else if([cmd isEqual:@"disconnected"]) {
		[self markPeerAsUnavailable:peer forReason:[NSError errorWithDomain:MeshPipeErrorDomain code:MeshPipeErrorPeerDisconnected userInfo:@{
			NSLocalizedDescriptionKey: [NSString stringWithFormat:@"%@ disconnected", peer.name],
		}]];
	} else if([cmd isEqual:@"youTimedOut"]) {
		[self announceTo:peer];
	} else if([cmd isEqual:@"keepalive"]) {
		[peer.expectKeepaliveTimer invalidate];
		peer.expectKeepaliveTimer = [NSTimer scheduledTimerWithTimeInterval:kKeepaliveExpectedWithin target:self selector:@selector(keepaliveExpected:) userInfo:peer repeats:YES];
	} else {
		MPLogDebug(@"Unexpected internal command %@", internal);
		return NO;
	}
	return YES;
}

- (void)markPeerAsAvailable:(MeshPipePeer*)peer
{
	if(![_peers containsObject:peer]) {
		MPLogDebug(@"Peer is now available: %@", peer);
		peer.expectKeepaliveTimer = [NSTimer scheduledTimerWithTimeInterval:kKeepaliveExpectedWithin target:self selector:@selector(keepaliveExpected:) userInfo:peer repeats:YES];
		[self willChangeValueForKey:@"peers"];
		[_peers addObject:peer];
		[self didChangeValueForKey:@"peers"];
		if([self.delegate respondsToSelector:@selector(meshPipe:acceptedNewPeer:)])
			[self.delegate meshPipe:self acceptedNewPeer:peer];
	}
}

- (void)markPeerAsUnavailable:(MeshPipePeer*)peer forReason:(NSError*)error
{
	if([_peers containsObject:peer]) {
		MPLogDebug(@"Peer is now unavailable: %@: reason %@", peer, error);
		[peer.expectKeepaliveTimer invalidate]; peer.expectKeepaliveTimer = nil;
		[self willChangeValueForKey:@"peers"];
		[_peers removeObject:peer];
		[self didChangeValueForKey:@"peers"];
		if([self.delegate respondsToSelector:@selector(meshPipe:lostPeer:withError:)])
			[self.delegate meshPipe:self lostPeer:peer withError:error];
	}
	peer.name = @"Unavailable";

}
@end

@implementation MeshPipePeer
- (instancetype)init
{
	if(!(self = [super init]))
		return nil;
	self.name = @"Unavailable";
	return self;
}

- (void)_send:(NSData*)data asType:(_MeshPipeMessageType)type
{
	NSMutableData *send = [NSMutableData dataWithCapacity:data.length + 1];
	[send appendBytes:&type length:1];
	[send appendData:data];
	
	// Send through the listenSocket so that the sending port is correct
    [self.parent.listenSocket sendData:send toHost:MeshPipeLocalHost port:self.port withTimeout:-1 tag:0];
}

- (void)sendData:(NSData*)data
{
	[self _send:data asType:_MeshPipeMessageTypeData];
}
- (void)sendInternal:(NSDictionary *)internal
{
	MPLogDebug(@"%@ sending internal: %@", self, internal);
	[self _send:SerializeInternal(internal) asType:_MeshPipeMessageTypeInternal];
}
- (NSString*)description
{
	return [NSString stringWithFormat:@"<%@@%p: %d %@>", [self class], self, self.port, self.name];
}
@end

@implementation MeshPipeSelfPeer
- (void)_send:(NSData*)data asType:(_MeshPipeMessageType)type
{
	MPLogDebug(@"Not sending to self");
}

@end

static NSData *SerializeInternal(NSDictionary *internal)
{
	NSError *err;
	NSData *d = [NSJSONSerialization dataWithJSONObject:internal options:0 error:&err];
	if(!d) {
		NSCAssert(d != nil, @"Couldn't serialize: %@", err);
		return nil;
	}
	return d; // [d gzippedData]; gzipped data is bigger!
}

static NSDictionary *DeserializeInternal(NSData *data)
{
	//NSData *unzipped = [data gunzippedData];
	NSError *err;
	id ret = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
	if(!ret) {
		MPLogDebug(@"Unable to deserialize: %@ %@", data, err);
		return nil;
	}
	return ret;
}

NSString *const MeshPipeErrorDomain = @"eu.thirdcog.meshpipe";
