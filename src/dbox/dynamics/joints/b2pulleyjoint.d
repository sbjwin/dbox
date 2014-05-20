
module dbox.dynamics.joints.b2pulleyjoint;

import core.stdc.float_;
import core.stdc.stdlib;
import core.stdc.string;

import dbox.common;
import dbox.dynamics;

/*
 * Copyright (c) 2006-2011 Erin Catto http://www.box2d.org
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

// #ifndef B2_PULLEY_JOINT_H
// #define B2_PULLEY_JOINT_H

import dbox.dynamics.joints.b2joint;

const float32 b2_minPulleyLength = 2.0f;

/// Pulley joint definition. This requires two ground anchors,
/// two dynamic body anchor points, and a pulley ratio.
class b2PulleyJointDef : b2JointDef
{
    this()
    {
        type = e_pulleyJoint;
        groundAnchorA.Set(-1.0f, 1.0f);
        groundAnchorB.Set(1.0f, 1.0f);
        localAnchorA.Set(-1.0f, 0.0f);
        localAnchorB.Set(1.0f, 0.0f);
        lengthA = 0.0f;
        lengthB = 0.0f;
        ratio   = 1.0f;
        collideConnected = true;
    }

    void Initialize(b2Body* bA, b2Body* bB,
                                      b2Vec2 groundA, b2Vec2 groundB,
                                      b2Vec2 anchorA, b2Vec2 anchorB,
                                      float32 r)
    {
        body_A         = bA;
        body_B         = bB;
        groundAnchorA = groundA;
        groundAnchorB = groundB;
        localAnchorA  = body_A.GetLocalPoint(anchorA);
        localAnchorB  = body_B.GetLocalPoint(anchorB);
        b2Vec2 dA = anchorA - groundA;
        lengthA = dA.Length();
        b2Vec2 dB = anchorB - groundB;
        lengthB = dB.Length();
        ratio   = r;
        assert(ratio > b2_epsilon);
    }

    /// Initialize the bodies, anchors, lengths, max lengths, and ratio using the world anchors.
    void Initialize(b2Body* body_A, b2Body* body_B,
                    b2Vec2 groundAnchorA, b2Vec2 groundAnchorB,
                    b2Vec2 anchorA, b2Vec2 anchorB,
                    float32 ratio);

    /// The first ground anchor in world coordinates. This point never moves.
    b2Vec2 groundAnchorA;

    /// The second ground anchor in world coordinates. This point never moves.
    b2Vec2 groundAnchorB;

    /// The local anchor point relative to body_A's origin.
    b2Vec2 localAnchorA;

    /// The local anchor point relative to body_B's origin.
    b2Vec2 localAnchorB;

    /// The a reference length for the segment attached to body_A.
    float32 lengthA = 0;

    /// The a reference length for the segment attached to body_B.
    float32 lengthB = 0;

    /// The pulley ratio, used to simulate a block-and-tackle.
    float32 ratio = 0;
}

/// The pulley joint is connected to two bodies and two fixed ground points.
/// The pulley supports a ratio such that:
/// length1 + ratio * length2 <= constant
/// Yes, the force transmitted is scaled by the ratio.
/// Warning: the pulley joint can get a bit squirrelly by itself. They often
/// work better when combined with prismatic joints. You should also cover the
/// the anchor points with static shapes to prevent one side from going to
/// zero length.
class b2PulleyJoint : b2Joint
{
    this(const(b2PulleyJointDef) def)
    {
        super(def);
        m_groundAnchorA = def.groundAnchorA;
        m_groundAnchorB = def.groundAnchorB;
        m_localAnchorA  = def.localAnchorA;
        m_localAnchorB  = def.localAnchorB;

        m_lengthA = def.lengthA;
        m_lengthB = def.lengthB;

        assert(def.ratio != 0.0f);
        m_ratio = def.ratio;

        m_constant = def.lengthA + m_ratio * def.lengthB;

        m_impulse = 0.0f;
    }

    override void InitVelocityConstraints(b2SolverData data)
    {
        m_indexA       = m_body_A.m_islandIndex;
        m_indexB       = m_body_B.m_islandIndex;
        m_localCenterA = m_body_A.m_sweep.localCenter;
        m_localCenterB = m_body_B.m_sweep.localCenter;
        m_invMassA     = m_body_A.m_invMass;
        m_invMassB     = m_body_B.m_invMass;
        m_invIA        = m_body_A.m_invI;
        m_invIB        = m_body_B.m_invI;

        b2Vec2  cA = data.positions[m_indexA].c;
        float32 aA = data.positions[m_indexA].a;
        b2Vec2  vA = data.velocities[m_indexA].v;
        float32 wA = data.velocities[m_indexA].w;

        b2Vec2  cB = data.positions[m_indexB].c;
        float32 aB = data.positions[m_indexB].a;
        b2Vec2  vB = data.velocities[m_indexB].v;
        float32 wB = data.velocities[m_indexB].w;

        b2Rot qA = b2Rot(aA);
        b2Rot qB = b2Rot(aB);

        m_rA = b2Mul(qA, m_localAnchorA - m_localCenterA);
        m_rB = b2Mul(qB, m_localAnchorB - m_localCenterB);

        // Get the pulley axes.
        m_uA = cA + m_rA - m_groundAnchorA;
        m_uB = cB + m_rB - m_groundAnchorB;

        float32 lengthA = m_uA.Length();
        float32 lengthB = m_uB.Length();

        if (lengthA > 10.0f * b2_linearSlop)
        {
            m_uA *= 1.0f / lengthA;
        }
        else
        {
            m_uA.SetZero();
        }

        if (lengthB > 10.0f * b2_linearSlop)
        {
            m_uB *= 1.0f / lengthB;
        }
        else
        {
            m_uB.SetZero();
        }

        // Compute effective mass.
        float32 ruA = b2Cross(m_rA, m_uA);
        float32 ruB = b2Cross(m_rB, m_uB);

        float32 mA = m_invMassA + m_invIA * ruA * ruA;
        float32 mB = m_invMassB + m_invIB * ruB * ruB;

        m_mass = mA + m_ratio * m_ratio * mB;

        if (m_mass > 0.0f)
        {
            m_mass = 1.0f / m_mass;
        }

        if (data.step.warmStarting)
        {
            // Scale impulses to support variable time steps.
            m_impulse *= data.step.dtRatio;

            // Warm starting.
            b2Vec2 PA = -(m_impulse) * m_uA;
            b2Vec2 PB = (-m_ratio * m_impulse) * m_uB;

            vA += m_invMassA * PA;
            wA += m_invIA * b2Cross(m_rA, PA);
            vB += m_invMassB * PB;
            wB += m_invIB * b2Cross(m_rB, PB);
        }
        else
        {
            m_impulse = 0.0f;
        }

        data.velocities[m_indexA].v = vA;
        data.velocities[m_indexA].w = wA;
        data.velocities[m_indexB].v = vB;
        data.velocities[m_indexB].w = wB;
    }

    override void SolveVelocityConstraints(b2SolverData data)
    {
        b2Vec2  vA = data.velocities[m_indexA].v;
        float32 wA = data.velocities[m_indexA].w;
        b2Vec2  vB = data.velocities[m_indexB].v;
        float32 wB = data.velocities[m_indexB].w;

        b2Vec2 vpA = vA + b2Cross(wA, m_rA);
        b2Vec2 vpB = vB + b2Cross(wB, m_rB);

        float32 Cdot    = -b2Dot(m_uA, vpA) - m_ratio * b2Dot(m_uB, vpB);
        float32 impulse = -m_mass * Cdot;
        m_impulse += impulse;

        b2Vec2 PA = -impulse * m_uA;
        b2Vec2 PB = -m_ratio * impulse * m_uB;
        vA += m_invMassA * PA;
        wA += m_invIA * b2Cross(m_rA, PA);
        vB += m_invMassB * PB;
        wB += m_invIB * b2Cross(m_rB, PB);

        data.velocities[m_indexA].v = vA;
        data.velocities[m_indexA].w = wA;
        data.velocities[m_indexB].v = vB;
        data.velocities[m_indexB].w = wB;
    }

    override bool SolvePositionConstraints(b2SolverData data)
    {
        b2Vec2  cA = data.positions[m_indexA].c;
        float32 aA = data.positions[m_indexA].a;
        b2Vec2  cB = data.positions[m_indexB].c;
        float32 aB = data.positions[m_indexB].a;

        b2Rot qA = b2Rot(aA);
        b2Rot qB = b2Rot(aB);

        b2Vec2 rA = b2Mul(qA, m_localAnchorA - m_localCenterA);
        b2Vec2 rB = b2Mul(qB, m_localAnchorB - m_localCenterB);

        // Get the pulley axes.
        b2Vec2 uA = cA + rA - m_groundAnchorA;
        b2Vec2 uB = cB + rB - m_groundAnchorB;

        float32 lengthA = uA.Length();
        float32 lengthB = uB.Length();

        if (lengthA > 10.0f * b2_linearSlop)
        {
            uA *= 1.0f / lengthA;
        }
        else
        {
            uA.SetZero();
        }

        if (lengthB > 10.0f * b2_linearSlop)
        {
            uB *= 1.0f / lengthB;
        }
        else
        {
            uB.SetZero();
        }

        // Compute effective mass.
        float32 ruA = b2Cross(rA, uA);
        float32 ruB = b2Cross(rB, uB);

        float32 mA = m_invMassA + m_invIA * ruA * ruA;
        float32 mB = m_invMassB + m_invIB * ruB * ruB;

        float32 mass = mA + m_ratio * m_ratio * mB;

        if (mass > 0.0f)
        {
            mass = 1.0f / mass;
        }

        float32 C = m_constant - lengthA - m_ratio * lengthB;
        float32 linearError = b2Abs(C);

        float32 impulse = -mass * C;

        b2Vec2 PA = -impulse * uA;
        b2Vec2 PB = -m_ratio * impulse * uB;

        cA += m_invMassA * PA;
        aA += m_invIA * b2Cross(rA, PA);
        cB += m_invMassB * PB;
        aB += m_invIB * b2Cross(rB, PB);

        data.positions[m_indexA].c = cA;
        data.positions[m_indexA].a = aA;
        data.positions[m_indexB].c = cB;
        data.positions[m_indexB].a = aB;

        return linearError < b2_linearSlop;
    }

    override b2Vec2 GetAnchorA() const
    {
        return m_body_A.GetWorldPoint(m_localAnchorA);
    }

    override b2Vec2 GetAnchorB() const
    {
        return m_body_B.GetWorldPoint(m_localAnchorB);
    }

    override b2Vec2 GetReactionForce(float32 inv_dt) const
    {
        b2Vec2 P = m_impulse * m_uB;
        return inv_dt * P;
    }

    override float32 GetReactionTorque(float32 inv_dt) const
    {
        B2_NOT_USED(inv_dt);
        return 0.0f;
    }

    b2Vec2 GetGroundAnchorA() const
    {
        return m_groundAnchorA;
    }

    b2Vec2 GetGroundAnchorB() const
    {
        return m_groundAnchorB;
    }

    float32 GetLengthA() const
    {
        return m_lengthA;
    }

    float32 GetLengthB() const
    {
        return m_lengthB;
    }

    float32 GetRatio() const
    {
        return m_ratio;
    }

    float32 GetCurrentLengthA() const
    {
        b2Vec2 p = m_body_A.GetWorldPoint(m_localAnchorA);
        b2Vec2 s = m_groundAnchorA;
        b2Vec2 d = p - s;
        return d.Length();
    }

    float32 GetCurrentLengthB() const
    {
        b2Vec2 p = m_body_B.GetWorldPoint(m_localAnchorB);
        b2Vec2 s = m_groundAnchorB;
        b2Vec2 d = p - s;
        return d.Length();
    }

    override void Dump()
    {
        int32 indexA = m_body_A.m_islandIndex;
        int32 indexB = m_body_B.m_islandIndex;

        b2Log("  b2PulleyJointDef jd;\n");
        b2Log("  jd.body_A = bodies[%d];\n", indexA);
        b2Log("  jd.body_B = bodies[%d];\n", indexB);
        b2Log("  jd.collideConnected = bool(%d);\n", m_collideConnected);
        b2Log("  jd.groundAnchorA.Set(%.15lef, %.15lef);\n", m_groundAnchorA.x, m_groundAnchorA.y);
        b2Log("  jd.groundAnchorB.Set(%.15lef, %.15lef);\n", m_groundAnchorB.x, m_groundAnchorB.y);
        b2Log("  jd.localAnchorA.Set(%.15lef, %.15lef);\n", m_localAnchorA.x, m_localAnchorA.y);
        b2Log("  jd.localAnchorB.Set(%.15lef, %.15lef);\n", m_localAnchorB.x, m_localAnchorB.y);
        b2Log("  jd.lengthA = %.15lef;\n", m_lengthA);
        b2Log("  jd.lengthB = %.15lef;\n", m_lengthB);
        b2Log("  jd.ratio = %.15lef;\n", m_ratio);
        b2Log("  joints[%d] = m_world.CreateJoint(&jd);\n", m_index);
    }

    override void ShiftOrigin(b2Vec2 newOrigin)
    {
        m_groundAnchorA -= newOrigin;
        m_groundAnchorB -= newOrigin;
    }



    b2Vec2  m_groundAnchorA;
    b2Vec2  m_groundAnchorB;
    float32 m_lengthA = 0;
    float32 m_lengthB = 0;

    // Solver shared
    b2Vec2  m_localAnchorA;
    b2Vec2  m_localAnchorB;
    float32 m_constant = 0;
    float32 m_ratio = 0;
    float32 m_impulse = 0;

    // Solver temp
    int32   m_indexA;
    int32   m_indexB;
    b2Vec2  m_uA;
    b2Vec2  m_uB;
    b2Vec2  m_rA;
    b2Vec2  m_rB;
    b2Vec2  m_localCenterA;
    b2Vec2  m_localCenterB;
    float32 m_invMassA = 0;
    float32 m_invMassB = 0;
    float32 m_invIA = 0;
    float32 m_invIB = 0;
    float32 m_mass = 0;
}

// #endif
/*
 * Copyright (c) 2007 Erin Catto http://www.box2d.org
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

import dbox.dynamics.joints.b2pulleyjoint;
import dbox.dynamics.b2body;
import dbox.dynamics.b2timestep;

// Pulley:
// length1 = norm(p1 - s1)
// length2 = norm(p2 - s2)
// C0 = (length1 + ratio * length2)_initial
// C = C0 - (length1 + ratio * length2)
// u1 = (p1 - s1) / norm(p1 - s1)
// u2 = (p2 - s2) / norm(p2 - s2)
// Cdot = -dot(u1, v1 + cross(w1, r1)) - ratio * dot(u2, v2 + cross(w2, r2))
// J = -[u1 cross(r1, u1) ratio * u2  ratio * cross(r2, u2)]
// K = J * invM * JT
// = invMass1 + invI1 * cross(r1, u1)^2 + ratio^2 * (invMass2 + invI2 * cross(r2, u2)^2)