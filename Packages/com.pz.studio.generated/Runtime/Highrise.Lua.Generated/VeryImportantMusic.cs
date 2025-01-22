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
    [AddComponentMenu("Lua/VeryImportantMusic")]
    [LuaRegisterType(0x40455bd128a35c88, typeof(LuaBehaviour))]
    public class VeryImportantMusic : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "3338d8f7991ea674ea9ced9766be9481";
        public override string ScriptGUID => s_scriptGUID;

        [SerializeField] public Highrise.AudioShader m_musicClip = default;
        [Range(0,1)]
        [SerializeField] public System.Double m_volume = 0.25;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), m_musicClip),
                CreateSerializedProperty(_script.GetPropertyAt(1), m_volume),
            };
        }
    }
}

#endif