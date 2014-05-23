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
module tests.applyforce;

import core.stdc.math;

import std.string;
import std.typecons;

import deimos.glfw.glfw3;

import dbox;

import framework.debug_draw;
import framework.test;

class ApplyForce : Test
{
    this()
    {
        m_world.SetGravity(b2Vec2(0.0f, 0.0f));

        const float32 k_restitution = 0.4f;

        b2Body* ground;
        {
            b2BodyDef bd;
            bd.position.Set(0.0f, 20.0f);
            ground = m_world.CreateBody(&bd);

            auto shape = new b2EdgeShape();

            b2FixtureDef sd;
            sd.shape       = shape;
            sd.density     = 0.0f;
            sd.restitution = k_restitution;

            // Left vertical
            shape.Set(b2Vec2(-20.0f, -20.0f), b2Vec2(-20.0f, 20.0f));
            ground.CreateFixture(&sd);

            // Right vertical
            shape.Set(b2Vec2(20.0f, -20.0f), b2Vec2(20.0f, 20.0f));
            ground.CreateFixture(&sd);

            // Top horizontal
            shape.Set(b2Vec2(-20.0f, 20.0f), b2Vec2(20.0f, 20.0f));
            ground.CreateFixture(&sd);

            // Bottom horizontal
            shape.Set(b2Vec2(-20.0f, -20.0f), b2Vec2(20.0f, -20.0f));
            ground.CreateFixture(&sd);
        }

        {
            b2Transform xf1;
            xf1.q.Set(0.3524f * b2_pi);
            xf1.p = xf1.q.GetXAxis();

            b2Vec2 vertices[3];
            vertices[0] = b2Mul(xf1, b2Vec2(-1.0f, 0.0f));
            vertices[1] = b2Mul(xf1, b2Vec2(1.0f, 0.0f));
            vertices[2] = b2Mul(xf1, b2Vec2(0.0f, 0.5f));

            b2PolygonShape poly1 = new b2PolygonShape();
            poly1.Set(vertices);

            b2FixtureDef sd1;
            sd1.shape   = poly1;
            sd1.density = 4.0f;

            b2Transform xf2;
            xf2.q.Set(-0.3524f * b2_pi);
            xf2.p = -xf2.q.GetXAxis();

            vertices[0] = b2Mul(xf2, b2Vec2(-1.0f, 0.0f));
            vertices[1] = b2Mul(xf2, b2Vec2(1.0f, 0.0f));
            vertices[2] = b2Mul(xf2, b2Vec2(0.0f, 0.5f));

            b2PolygonShape poly2 = new b2PolygonShape();
            poly2.Set(vertices);

            b2FixtureDef sd2;
            sd2.shape   = poly2;
            sd2.density = 2.0f;

            b2BodyDef bd;
            bd.type = b2_dynamicBody;
            bd.angularDamping = 2.0f;
            bd.linearDamping  = 0.5f;

            bd.position.Set(0.0f, 2.0);
            bd.angle      = b2_pi;
            bd.allowSleep = false;
            m_body        = m_world.CreateBody(&bd);
            m_body.CreateFixture(&sd1);
            m_body.CreateFixture(&sd2);
        }

        {
            auto shape = new b2PolygonShape();
            shape.SetAsBox(0.5f, 0.5f);

            b2FixtureDef fd;
            fd.shape    = shape;
            fd.density  = 1.0f;
            fd.friction = 0.3f;

            for (int i = 0; i < 10; ++i)
            {
                b2BodyDef bd;
                bd.type = b2_dynamicBody;

                bd.position.Set(0.0f, 5.0f + 1.54f * i);
                b2Body* body_ = m_world.CreateBody(&bd);

                body_.CreateFixture(&fd);

                float32 gravity = 10.0f;
                float32 I       = body_.GetInertia();
                float32 mass    = body_.GetMass();

                // For a circle: I = 0.5 * m * r * r ==> r = sqrt(2 * I / m)
                float32 radius = b2Sqrt(2.0f * I / mass);

                b2FrictionJointDef jd = new b2FrictionJointDef();
                jd.localAnchorA.SetZero();
                jd.localAnchorB.SetZero();
                jd.bodyA = ground;
                jd.bodyB = body_;
                jd.collideConnected = true;
                jd.maxForce         = mass * gravity;
                jd.maxTorque        = mass * radius * gravity;

                m_world.CreateJoint(jd);
            }
        }
    }

    override void Keyboard(int key)
    {
        switch (key)
        {
            case GLFW_KEY_W:
            {
                b2Vec2 f = m_body.GetWorldVector(b2Vec2(0.0f, -200.0f));
                b2Vec2 p = m_body.GetWorldPoint(b2Vec2(0.0f, 2.0f));
                m_body.ApplyForce(f, p, true);
            }
            break;

            case GLFW_KEY_A:
            {
                m_body.ApplyTorque(50.0f, true);
            }
            break;

            case GLFW_KEY_D:
            {
                m_body.ApplyTorque(-50.0f, true);
            }
            break;

            default:
                break;
        }
    }

    static Test Create()
    {
        return new typeof(this);
    }

    b2Body* m_body;
}
