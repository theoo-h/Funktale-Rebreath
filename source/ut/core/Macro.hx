package ut.core;

import haxe.macro.*;
import haxe.macro.Expr;

class Macro
{
    public static final UNDERTALE_PACKAGES:Array<String> = [
        'ut',
        'ut.core'
    ];
    public static function includeUndertale():Void
    {
        #if macro
        for (pkg in UNDERTALE_PACKAGES)
            Compiler.include(pkg);
        #end
    }
}