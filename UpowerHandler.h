/* UpowerHandler.h
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

#ifndef UpowerHandler_H
#define UpowerHandler_H

#include <Foundation/Foundation.h>
#include <DBusKit/DKNotificationCenter.h>

/**
 * <p><code>UpowerHandler</code> is a wrapper class to access the UPower
 * d-bus interfaces.</p>
 */
@interface UpowerHandler: NSObject
{
    DKNotificationCenter *center;
    NSMutableDictionary *devicePropertyChangedHandlers;
    id deviceChangedHandler;
}

- (id) init;
- (void) dealloc;

- (NSArray *) enumerateDevices;

- (BOOL) registerPropertyChangedHandler: (id)handler
                              forDevice: (DKProxy *)device;
- (void) unregisterPropertyChangedHandler: (id)handler
                                forDevice: (DKProxy *)device;

- (BOOL) registerDeviceChangedHandler: (id)handler;
- (void) unregisterDeviceChangedHandler: (id)handler;

/*
- (NSArray *) getStrlistProperty: (NSString *) property
                       forDevice: (NSString *) device;
- (BOOL) getBooleanProperty: (NSString *) property
                  forDevice: (NSString *) device;
- (NSString *) getStringProperty: (NSString *) property
                       forDevice: (NSString *) device;
- (BOOL) propertyExists: (NSString *) property
              forDevice: (NSString *) device;
*/
@end


#endif
