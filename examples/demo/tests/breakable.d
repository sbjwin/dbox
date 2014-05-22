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
module tests.breakable;

import core.stdc.math;

import std.string;
import std.typecons;

import deimos.glfw.glfw3;

import dbox;

import framework.debug_draw;
import framework.test;

// This is used to test sensor shapes.
class Breakable : Test
{
    this()
    {
        // Ground body_
        {
            b2BodyDef bd;
            b2Body* ground = m_world.CreateBody(&bd);

            auto shape = new b2EdgeShape();
            shape.Set(b2Vec2(-40.0f, 0.0f), b2Vec2(40.0f, 0.0f));
            ground.CreateFixture(shape, 0.0f);
        }

        // Breakable dynamic body_
        {
            b2BodyDef bd;
            bd.type = b2_dynamicBody;
            bd.position.Set(0.0f, 40.0f);
            bd.angle = 0.25f * b2_pi;
            m_body1  = m_world.CreateBody(&bd);

            m_shape1 = new typeof(m_shape1);
            m_shape1.SetAsBox(0.5f, 0.5f, b2Vec2(-0.5f, 0.0f), 0.0f);
            m_piece1 = m_body1.CreateFixture(m_shape1, 1.0f);

            m_shape2 = new typeof(m_shape2);
            m_shape2.SetAsBox(0.5f, 0.5f, b2Vec2(0.5f, 0.0f), 0.0f);
            m_piece2 = m_body1.CreateFixture(m_shape2, 1.0f);
        }

        m_break = false;
        m_broke = false;
    }

    override void PostSolve(b2Contact contact, const(b2ContactImpulse)* impulse)
    {
        if (m_broke)
        {
            // The body_ already broke.
            return;
        }

        // Should the body_ break?
        int32 count = contact.GetManifold().pointCount;

        float32 maxImpulse = 0.0f;

        for (int32 i = 0; i < count; ++i)
        {
            maxImpulse = b2Max(maxImpulse, impulse.normalImpulses[i]);
        }

        if (maxImpulse > 40.0f)
        {
            // Flag the body_ for breaking.
            m_break = true;
        }
    }

    void Break()
    {
        // Create two bodies from one.
        b2Body* body1  = m_piece1.GetBody();
        b2Vec2  center = body1.GetWorldCenter();

        body1.DestroyFixture(m_piece2);
        m_piece2 = null;

        b2BodyDef bd;
        bd.type     = b2_dynamicBody;
        bd.position = body1.GetPosition();
        bd.angle    = body1.GetAngle();

        b2Body* body2 = m_world.CreateBody(&bd);
        m_piece2 = body2.CreateFixture(m_shape2, 1.0f);

        // Compute consistent velocities for new bodies based on
        // cached velocity.
        b2Vec2 center1 = body1.GetWorldCenter();
        b2Vec2 center2 = body2.GetWorldCenter();

        b2Vec2 velocity1 = m_velocity + b2Cross(m_angularVelocity, center1 - center);
        b2Vec2 velocity2 = m_velocity + b2Cross(m_angularVelocity, center2 - center);

        body1.SetAngularVelocity(m_angularVelocity);
        body1.SetLinearVelocity(velocity1);

        body2.SetAngularVelocity(m_angularVelocity);
        body2.SetLinearVelocity(velocity2);
    }

    override void Step(Settings* settings)
    {
        if (m_break)
        {
            Break();
            m_broke = true;
            m_break = false;
        }

        // Cache velocities to improve movement on breakage.
        if (m_broke == false)
        {
            m_velocity        = m_body1.GetLinearVelocity();
            m_angularVelocity = m_body1.GetAngularVelocity();
        }

        Test.Step(settings);
    }

    b2Body* m_body1;
    b2Vec2  m_velocity;
    float32 m_angularVelocity;
    b2PolygonShape m_shape1;
    b2PolygonShape m_shape2;
    b2Fixture* m_piece1;
    b2Fixture* m_piece2;

    bool m_broke;
    bool m_break;

    static Test Create()
    {
        return new typeof(this);
    }
}
