/* Battery.h
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

#ifndef BATTERY_H
#define BATTERY_H

#include <Foundation/Foundation.h>
#include "UpowerHandler.h"
#include "UpowerProtocols.h"
#include "BatteryIconController.h"


@interface Battery: NSObject
{
    UpowerHandler *upHandler;
    id <NSObject,DeviceProperties> device;
    BatteryIconController *biController;

    NSString *name;
    int chargeState;
    int percentage;
    int remainingTime;
    int warningThreshold;
    BOOL mustShowWarning;
}

- (id) initFromDevice: (DKProxy *)proxy
            upHandler: (UpowerHandler *)handler;

- (NSString *) name;
- (int) percentage;
- (int) remainingTime;

- (void) propertyModified: (id)data;

@end

#endif
