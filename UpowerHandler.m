/* UpowerHandler.m
 *  
 * Copyright (C) 2011 Andreas Schik
 *
 * Author: Andreas Schik <andreas@schik.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#import <DBusKit/DBusKit.h>
#import "UpowerHandler.h"
#include "UpowerProtocols.h"

static NSString * const DBUS_SVCUP = @"org.freedesktop.UPower";
static NSString * const UPOWER_PATH = @"/org/freedesktop/UPower";
static NSString * const DBUS_IFUPOWER = @"org.freedesktop.UPower";

static NSString * const SIG_DEVICEPROP_CHANGED = @"DKSignal_org.freedesktop.UPower.Device_Changed";
static NSString * const SIG_DEVICE_ADDED = @"DKSignal_org.freedesktop.UPower_DeviceAdded";
static NSString * const SIG_DEVICE_REMOVED = @"DKSignal_org.freedesktop.UPower_DeviceRemoved";

@interface UpowerHandler (Private)

- (id) deviceChangedHandler;
- (id) propertyModifiedHandlerForDevice: (NSString *)device;
@end


@implementation UpowerHandler (Private)

- (id) deviceChangedHandler
{
    return deviceChangedHandler;
}

- (id) propertyModifiedHandlerForDevice: (NSString *)device
{
    return [devicePropertyChangedHandlers objectForKey: device];
}

@end


@implementation UpowerHandler: NSObject

- (id) init
{
    devicePropertyChangedHandlers = nil;
    deviceChangedHandler = nil;

    id h = [super init];
    if (h != nil) {
	center = [[DKNotificationCenter systemBusCenter] retain];
        devicePropertyChangedHandlers = [NSMutableDictionary new];
        self = h;
    } else {
        [self dealloc];
        self = nil;
    }

    return self;
}

- (void) dealloc
{
    DESTROY(devicePropertyChangedHandlers);
    [center release];

    [super dealloc];
}

- (BOOL) registerPropertyChangedHandler: (id)handler
                              forDevice: (DKProxy *)device
{
    if (![handler respondsToSelector: @selector(propertyModified:)]) {
        return NO;
    }
    if ([devicePropertyChangedHandlers objectForKey: [device _path]] != nil) {
        return NO;
    }

    [center addObserver: handler
               selector: @selector(propertyModified:)
                   name: SIG_DEVICEPROP_CHANGED
                 object: device];

    [devicePropertyChangedHandlers setObject: handler forKey: [device _path]];
    return YES;
}

- (void) unregisterPropertyChangedHandler: (id)handler
                                forDevice: (DKProxy *)device
{
    if ([devicePropertyChangedHandlers objectForKey: [device _path]] != handler) {
        return;
    }

    [devicePropertyChangedHandlers removeObjectForKey: [device _path]];

    [center removeObserver: handler
                      name: SIG_DEVICEPROP_CHANGED
                    object: device];
}

- (BOOL) registerDeviceChangedHandler: (id)handler
{
    if (![handler respondsToSelector: @selector(deviceAdded:)]) {
        return NO;
    }
    if (![handler respondsToSelector: @selector(deviceRemoved:)]) {
        return NO;
    }
    if (deviceChangedHandler != nil) {
        return (deviceChangedHandler == handler);
    }
    ASSIGN(deviceChangedHandler, handler);

    [center addObserver: handler
               selector: @selector(deviceAdded:)
                  name: SIG_DEVICE_ADDED
                object: nil];
    [center addObserver: handler
               selector: @selector(deviceRemoved:)
                  name: SIG_DEVICE_REMOVED
                object: nil];
    return YES;
}

- (void) unregisterDeviceChangedHandler: (id)handler
{
    if (deviceChangedHandler != handler) {
        return;
    }
    [center removeObserver: handler
                      name: SIG_DEVICE_ADDED
                    object: nil];
    [center removeObserver: handler
                      name: SIG_DEVICE_REMOVED
                    object: nil];
    DESTROY(deviceChangedHandler);
}

/*
- (NSArray *) getStrlistProperty: (NSString *) property
                       forDevice: (NSString *) device
{
    NSConnection *c;
    NSArray *propList;
    id <NSObject,HalDevice> remote;

    c = [NSConnection connectionWithReceivePort:[DKPort systemBusPort]
                                       sendPort:[[DKPort alloc] initWithRemote: DBUS_SVCHAL
                                                                         onBus: DKDBusSystemBus]];

    remote = (id <NSObject,HalDevice>)[c proxyAtPath: device];
    [remote setPrimaryDBusInterface: DBUS_IFDEVICE];
    NS_DURING
    {
      propList = [remote GetPropertyStringList: property];
    }
    NS_HANDLER
    {
	NSDebugLog(@"Exception %@ querying prop %@ for device %@. Reason:\n%@",
            [localException name], property, device, [localException reason]);
        propList = nil;
    }
    NS_ENDHANDLER

    [c invalidate];
    return [propList retain];
}

- (BOOL) getBooleanProperty: (NSString *) property
                  forDevice: (NSString *) device
{
    NSConnection *c;
    NSNumber *result;
    id <NSObject,HalDevice> remote;

    c = [NSConnection connectionWithReceivePort:[DKPort systemBusPort]
                                       sendPort:[[DKPort alloc] initWithRemote: DBUS_SVCHAL
                                                                         onBus: DKDBusSystemBus]];

    remote = (id <NSObject,HalDevice>)[c proxyAtPath: device];
    [remote setPrimaryDBusInterface: DBUS_IFDEVICE];
    NS_DURING
    {
      result = [remote GetPropertyBoolean: property];
    }
    NS_HANDLER
    {
	NSDebugLog(@"Exception %@ querying prop %@ for device %@. Reason:\n%@",
            [localException name], property, device, [localException reason]);
        result = [NSNumber numberWithBool: NO];
    }
    NS_ENDHANDLER

    [c invalidate];
    return [result boolValue];
}

- (NSString *) getStringProperty: (NSString *) property
                       forDevice: (NSString *) device
{
    NSConnection *c;
    NSString *result;
    id <NSObject,HalDevice> remote;

    c = [NSConnection connectionWithReceivePort:[DKPort systemBusPort]
                                       sendPort:[[DKPort alloc] initWithRemote: DBUS_SVCHAL
                                                                         onBus: DKDBusSystemBus]];

    remote = (id <NSObject,HalDevice>)[c proxyAtPath: device];
    [remote setPrimaryDBusInterface: DBUS_IFDEVICE];
    NS_DURING
    {
      result = [remote GetPropertyString: property];
    }
    NS_HANDLER
    {
	NSDebugLog(@"Exception %@ querying prop %@ for device %@. Reason:\n%@",
            [localException name], property, device, [localException reason]);
        result = nil;
    }
    NS_ENDHANDLER

    [c invalidate];
    return [result retain];
}

- (BOOL) propertyExists: (NSString *) property
              forDevice: (NSString *) device
{
    NSConnection *c;
    NSNumber *result;
    id <NSObject,HalDevice> remote;

    c = [NSConnection connectionWithReceivePort:[DKPort systemBusPort]
                                       sendPort:[[DKPort alloc] initWithRemote: DBUS_SVCHAL
                                                                         onBus: DKDBusSystemBus]];

    remote = (id <NSObject,HalDevice>)[c proxyAtPath: device];
    [remote setPrimaryDBusInterface: DBUS_IFDEVICE];
    NS_DURING
    {
      result = [remote PropertyExists: property];
    }
    NS_HANDLER
    {
	NSDebugLog(@"Exception %@ querying prop %@ for device %@. Reason:\n%@",
            [localException name], property, device, [localException reason]);
        result = [NSNumber numberWithBool: NO];
    }
    NS_ENDHANDLER

    [c invalidate];
    return [result boolValue];
}
*/
- (NSArray *) enumerateDevices
{
    NSConnection *c;
    NSArray *result;
    id <NSObject,UPower> remote;

    c = [NSConnection connectionWithReceivePort:[DKPort systemBusPort]
                                       sendPort:[[DKPort alloc] initWithRemote: DBUS_SVCUP
                                                                         onBus: DKDBusSystemBus]];

    remote = (id <NSObject,UPower>)
                         [c proxyAtPath: UPOWER_PATH];
    [remote setPrimaryDBusInterface: DBUS_IFUPOWER];
    NS_DURING
    {
      result = [remote EnumerateDevices];
    }
    NS_HANDLER
    {
	NSDebugLog(@"Exception %@ enumerating devices. Reason:\n%@",
            [localException name], [localException reason]);
        result = nil;
    }
    NS_ENDHANDLER

    [c invalidate];
    return result;
}


@end
