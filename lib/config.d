/**
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module lib.config;

private import lib.common.config;
private import lib.compiler.config;
private import lib.gc.config;

pragma( lib, "common\\" ~ lib.common.config.lib );
pragma( lib, "compiler\\" ~ lib.compiler.config.lib );
pragma( lib, "gc\\" ~ lib.gc.config.lib );