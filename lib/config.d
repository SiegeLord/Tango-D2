/**
 * Authors:   Sean Kelly
 * Copyright: Copyright (C) 2006 Sean Kelly
 * License:   See about.d
 */
module lib.config;

private import lib.common.config;
private import lib.compiler.config;
private import lib.gc.config;

pragma( lib, lib.common.config.lib );
pragma( lib, lib.compiler.config.lib );
pragma( lib, lib.gc.config.lib );