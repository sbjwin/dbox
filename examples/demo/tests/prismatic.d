/*
 * Copyright (c) 2006-2007 Erin Catto http://www.box2d.org
 *
 * This software is provided 'as-is', without any express or implied
 * warranty.  In no event will the authors be held liable for any damages
 * arising from the use of this software.
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 * 1. The origin of this software must not be misrepresented; you must not
 * claim that you wrote the original software. If you use this software
 * in a product, an acknowledgment in the product documentation would be
 * appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 * misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */
module tests.prismatic;

import core.stdc.math;

import std.string;
import std.typecons;

import deimos.glfw.glfw3;

import dbox;

import framework.debug_draw;
import framework.test;

class Prismatic : Test
{
    this()
    {
        b2Body* ground = null;
        {
            b2BodyDef bd;
            ground = m_world.CreateBody(&bd);

            auto shape = new b2EdgeShape();
            shape.Set(b2Vec2(-40.0f, 0.0f), b2Vec2(40.0f, 0.0f));
            ground.CreateFixture(shape, 0.0f);
        }

        {
            auto shape = new b2PolygonShape();
            shape.SetAsBox(2.0f, 0.5f);

            b2BodyDef bd;
            bd.type = b2_dynamicBody;
            bd.position.Set(-10.0f, 10.0f);
            bd.angle      = 0.5f * b2_pi;
            bd.allowSleep = false;
            b2Body* body_ = m_world.CreateBody(&bd);
            body_.CreateFixture(shape, 5.0f);

            b2PrismaticJointDef pjd = new b2PrismaticJointDef();

            // Bouncy limit
            b2Vec2 axis = b2Vec2(2.0f, 1.0f);
            axis.Normalize();
            pjd.Initialize(ground, body_, b2Vec2(0.0f, 0.0f), axis);

            // Non-bouncy limit
            // pjd.Initialize(ground, body_, b2Vec2(-10.0f, 10.0f), b2Vec2(1.0f, 0.0f));

            pjd.motorSpeed       = 10.0f;
            pjd.maxMotorForce    = 10000.0f;
            pjd.enableMotor      = true;
            pjd.lowerTranslation = 0.0f;
            pjd.upperTranslation = 20.0f;
            pjd.enableLimit      = true;

            m_joint = cast(b2PrismaticJoint)m_world.CreateJoint(pjd);
        }
    }

    override void Keyboard(int key)
    {
        switch (key)
        {
            case GLFW_KEY_L:
                m_joint.EnableLimit(!m_joint.IsLimitEnabled());
                break;

            case GLFW_KEY_M:
                m_joint.EnableMotor(!m_joint.IsMotorEnabled());
                break;

            case GLFW_KEY_S:
                m_joint.SetMotorSpeed(-m_joint.GetMotorSpeed());
                break;

            default:
                break;
        }
    }

    override void Step(Settings* settings)
    {
        super.Step(settings);

        g_debugDraw.DrawString(5, m_textLine, "Keys: (l) limits, (m) motors, (s) speed");
        m_textLine += DRAW_STRING_NEW_LINE;
        float32 force = m_joint.GetMotorForce(settings.hz);
        g_debugDraw.DrawString(5, m_textLine, format("Motor Force = %4.0f", cast(float)force));
        m_textLine += DRAW_STRING_NEW_LINE;
    }

    static Test Create()
    {
        return new typeof(this);
    }

    b2PrismaticJoint m_joint;
}