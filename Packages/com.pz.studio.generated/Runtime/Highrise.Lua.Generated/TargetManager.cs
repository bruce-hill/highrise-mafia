/*

    Copyright (c) 2025 Pocketz World. All rights reserved.

    This is a generated file, do not edit!

    Generated by com.pz.studio
*/

#if UNITY_EDITOR

using System;
using System.Linq;
using UnityEngine;
using Highrise.Client;
using Highrise.Studio;
using Highrise.Lua;

namespace Highrise.Lua.Generated
{
    [AddComponentMenu("Lua/TargetManager")]
    [LuaRegisterType(0x30c1c20e62401797, typeof(LuaBehaviour))]
    public class TargetManager : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "3b304adc9f2597e4c8b4cb12982bebca";
        public override string ScriptGUID => s_scriptGUID;


        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
            };
        }
    }
}

#endif
