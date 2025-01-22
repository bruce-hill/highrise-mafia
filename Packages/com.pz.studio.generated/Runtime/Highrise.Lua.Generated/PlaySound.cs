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
    [AddComponentMenu("Lua/PlaySound")]
    [LuaRegisterType(0x5d67efd8d82fa82, typeof(LuaBehaviour))]
    public class PlaySound : LuaBehaviourThunk
    {
        private const string s_scriptGUID = "6259ae51eea8c9c45bda1e0f667ef3ec";
        public override string ScriptGUID => s_scriptGUID;

        [Tooltip("Audio shader to play. To create an Audio Shader, right click an audio file then go to Create->Highrise->Audio->Audio Shader")]
        [SerializeField] public Highrise.AudioShader _audioShader = default;
        [Tooltip("Delay in seconds before playing the sound.")]
        [SerializeField] public System.Double _secondsDelay = 0;

        protected override SerializedPropertyValue[] SerializeProperties()
        {
            if (_script == null)
                return Array.Empty<SerializedPropertyValue>();

            return new SerializedPropertyValue[]
            {
                CreateSerializedProperty(_script.GetPropertyAt(0), _audioShader),
                CreateSerializedProperty(_script.GetPropertyAt(1), _secondsDelay),
            };
        }
    }
}

#endif