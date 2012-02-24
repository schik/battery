/* main.m
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

#include <AppKit/NSApplication.h>

#include "ApplicationDelegate.h"

int main(int argc, const char *argv[])
{
    CREATE_AUTORELEASE_POOL(pool);
    NSProcessInfo *info = [NSProcessInfo processInfo];
    NSMutableArray *args = AUTORELEASE ([[info arguments] mutableCopy]);
    BOOL subtask = YES;

    if ([[info arguments] containsObject: @"--daemon"]) {
        subtask = NO;
    }

    if (subtask) {
        NSTask *task = [NSTask new];
    
        NS_DURING
        {
            [args removeObjectAtIndex: 0];
            [args addObject: @"--daemon"];
            if (GSDebugSet(@"dflt") == YES) {
                [args addObject: @"--GNU-Debug=dflt"];
            }
            [task setLaunchPath: [[NSBundle mainBundle] executablePath]];
            [task setArguments: args];
            [task setEnvironment: [info environment]];
            [task launch];
            DESTROY (task);
        }
        NS_HANDLER
        {
            NSDebugLog(@"Unable to launch the battery task. exiting.\n");
            DESTROY (task);
        }
        NS_ENDHANDLER
      
        exit(EXIT_FAILURE);
    }

    RELEASE(pool);
    {
        CREATE_AUTORELEASE_POOL (pool);
        // We need the following to be able to access services.
        [NSApplication sharedApplication];
        [NSApp setDelegate: [[ApplicationDelegate alloc] init]];

        NSApplicationMain(argc, argv);
        RELEASE (pool);
    }
    
    exit(EXIT_SUCCESS);
}

