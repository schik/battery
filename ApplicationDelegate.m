/* ApplicationDelegate.m
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

#include <AppKit/AppKit.h>
#include "ApplicationDelegate.h"
#include "Battery.h"
#include "UpowerProtocols.h"

@interface ApplicationDelegate (Private)
- (void) checkNewDevice: (DKProxy *)proxy;
- (void) batteryAdded: (DKProxy *)proxy;
@end

@implementation ApplicationDelegate (Private)

- (void) checkNewDevice: (DKProxy *)proxy
{
    id <NSObject,DeviceProperties> remote = (id <NSObject,DeviceProperties>)proxy;
    [remote setPrimaryDBusInterface: @"org.freedesktop.UPower.Device"];
    NSNumber *type = [remote Type];
    NSNumber *supply = [remote PowerSupply];
    NSDebugLog(@"New device %@ of type %d", [remote NativePath], [type intValue]);
    if (([type intValue] == TYPE_BATTERY)
            && ([supply boolValue] == YES)) {
        [self batteryAdded: proxy];
    }
}

- (void) batteryAdded: (DKProxy *)proxy;
{
    Battery *battery = [[Battery alloc] initFromDevice: proxy
                                             upHandler: upHandler];
    [batteries setObject: battery forKey: [proxy NativePath]];
    RELEASE(battery);
}

@end

@implementation ApplicationDelegate

- (id) init
{
    self = [super init];
  
    if (self) {
    batteries = [NSMutableDictionary dictionary];
    RETAIN(batteries);
        upHandler = [UpowerHandler new];
    }
  
    return self;
}

- (void) dealloc
{
    DESTROY(batteries);
    DESTROY(upHandler);
    [super dealloc];
}

- (void) applicationWillFinishLaunching: (NSNotification *) notif
{
}

- (void) applicationDidFinishLaunching: (NSNotification *) notif
{
    NSArray *devices = [upHandler enumerateDevices];
    if (devices != nil) {
        int i;
        for (i = 0; i < [devices count]; i++) {
            DKProxy *dkp = (DKProxy *)[devices objectAtIndex: i];
            [self checkNewDevice: dkp];
        }
        if ([devices count] == 0) {
            NSLog(@"No power management devices found");
        }
    }
    [upHandler registerDeviceChangedHandler: self];
}

- (void)applicationWillTerminate: (NSNotification *)notif
{
}

- (BOOL)applicationShouldTerminate:(id)sender
{
    NSDebugLog(@"Application will exit");

    return YES;
}

- (void) deviceAdded: (id)data
{
    NSDictionary *userInfo = [(NSNotification*)data userInfo];
    DKProxy *dkp = [userInfo objectForKey: @"device"];
    [self checkNewDevice: dkp];
}

- (void) deviceRemoved: (id)data
{
}


@end

