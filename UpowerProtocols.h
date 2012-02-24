/* UpowerProtocols.h
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

#ifndef UpowerProtocols_H
#define UpowerProtocols_H

#include <Foundation/Foundation.h>

/**
 * The protocol for org.freedesktop.DBus.Properties
 */
@protocol DeviceProperties
- (NSString *) NativePath;
- (NSNumber *) Type;
- (NSNumber *) IsPresent;
- (NSNumber *) PowerSupply;
- (NSNumber *) Percentage;
- (NSNumber *) Energy;
- (NSNumber *) State;
- (NSNumber *) TimeToEmpty;
- (NSNumber *) TimeToFull;
@end


/**
 * The protocol for org.freedesktop.UPower
 */
@protocol UPower
- (NSArray *) EnumerateDevices;
@end

#define TYPE_LINE 1
#define TYPE_BATTERY 2

#define STATE_CHARGING 1
#define STATE_DISCHARGING 2
#define STATE_EMPTY 3
#define STATE_FULL 4

#endif
