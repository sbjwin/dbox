module dbox.dynamics.joints.b2weldjoint;

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

// #ifndef B2_WELD_JOINT_H
// #define B2_WELD_JOINT_H

import dbox.dynamics.joints.b2joint;

/// Weld joint definition. You need to specify local anchor points
/// where they are attached and the relative body angle. The position
/// of the anchor points is important for computing the reaction torque.
class b2WeldJointDef : b2JointDef
{
    this()
    {
        type = e_weldJoint;
        localAnchorA.Set(0.0f, 0.0f);
        localAnchorB.Set(0.0f, 0.0f);
        referenceAngle = 0.0f;
        frequencyHz    = 0.0f;
        dampingRatio   = 0.0f;
    }

    /// Initialize the bodies, anchors, and reference angle using a world
    /// anchor point.

    // Point-to-point constraint
    // C = p2 - p1
    // Cdot = v2 - v1
    // = v2 + cross(w2, r2) - v1 - cross(w1, r1)
    // J = [-I -r1_skew I r2_skew ]
    // Identity used:
    // w k % (rx i + ry j) = w * (-ry i + rx j)

    // Angle constraint
    // C = angle2 - angle1 - referenceAngle
    // Cdot = w2 - w1
    // J = [0 0 -1 0 0 1]
    // K = invI1 + invI2

    void Initialize(b2Body* bA, b2Body* bB, b2Vec2 anchor)
    {
        body_A          = bA;
        body_B          = bB;
        localAnchorA   = body_A.GetLocalPoint(anchor);
        localAnchorB   = body_B.GetLocalPoint(anchor);
        referenceAngle = body_B.GetAngle() - body_A.GetAngle();
    }

    /// The local anchor point relative to body_A's origin.
    b2Vec2 localAnchorA;

    /// The local anchor point relative to body_B's origin.
    b2Vec2 localAnchorB;

    /// The body_B angle minus body_A angle in the reference state (radians).
    float32 referenceAngle = 0;

    /// The mass-spring-damper frequency in Hertz. Rotation only.
    /// Disable softness with a value of 0.
    float32 frequencyHz = 0;

    /// The damping ratio. 0 = no damping, 1 = critical damping.
    float32 dampingRatio = 0;
}

/// A weld joint essentially glues two bodies together. A weld joint may
/// distort somewhat because the island constraint solver is approximate.
class b2WeldJoint : b2Joint
{
    this(const(b2WeldJointDef) def)
    {
        super(def);
        m_localAnchorA   = def.localAnchorA;
        m_localAnchorB   = def.localAnchorB;
        m_referenceAngle = def.referenceAngle;
        m_frequencyHz    = def.frequencyHz;
        m_dampingRatio   = def.dampingRatio;

        m_impulse.SetZero();
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

        float32 aA = data.positions[m_indexA].a;
        b2Vec2  vA = data.velocities[m_indexA].v;
        float32 wA = data.velocities[m_indexA].w;

        float32 aB = data.positions[m_indexB].a;
        b2Vec2  vB = data.velocities[m_indexB].v;
        float32 wB = data.velocities[m_indexB].w;

        b2Rot qA = b2Rot(aA);
        b2Rot qB = b2Rot(aB);

        m_rA = b2Mul(qA, m_localAnchorA - m_localCenterA);
        m_rB = b2Mul(qB, m_localAnchorB - m_localCenterB);

        // J = [-I -r1_skew I r2_skew]
        // [ 0       -1 0       1]
        // r_skew = [-ry; rx]

        // Matlab
        // K = [ mA+r1y^2*iA+mB+r2y^2*iB,  -r1y*iA*r1x-r2y*iB*r2x,          -r1y*iA-r2y*iB]
        // [  -r1y*iA*r1x-r2y*iB*r2x, mA+r1x^2*iA+mB+r2x^2*iB,           r1x*iA+r2x*iB]
        // [          -r1y*iA-r2y*iB,           r1x*iA+r2x*iB,                   iA+iB]

        float32 mA = m_invMassA, mB = m_invMassB;
        float32 iA = m_invIA, iB = m_invIB;

        b2Mat33 K;
        K.ex.x = mA + mB + m_rA.y * m_rA.y * iA + m_rB.y * m_rB.y * iB;
        K.ey.x = -m_rA.y * m_rA.x * iA - m_rB.y * m_rB.x * iB;
        K.ez.x = -m_rA.y * iA - m_rB.y * iB;
        K.ex.y = K.ey.x;
        K.ey.y = mA + mB + m_rA.x * m_rA.x * iA + m_rB.x * m_rB.x * iB;
        K.ez.y = m_rA.x * iA + m_rB.x * iB;
        K.ex.z = K.ez.x;
        K.ey.z = K.ez.y;
        K.ez.z = iA + iB;

        if (m_frequencyHz > 0.0f)
        {
            K.GetInverse22(&m_mass);

            float32 invM = iA + iB;
            float32 m    = invM > 0.0f ? 1.0f / invM : 0.0f;

            float32 C = aB - aA - m_referenceAngle;

            // Frequency
            float32 omega = 2.0f * b2_pi * m_frequencyHz;

            // Damping coefficient
            float32 d = 2.0f * m * m_dampingRatio * omega;

            // Spring stiffness
            float32 k = m * omega * omega;

            // magic formulas
            float32 h = data.step.dt;
            m_gamma = h * (d + h * k);
            m_gamma = m_gamma != 0.0f ? 1.0f / m_gamma : 0.0f;
            m_bias  = C * h * k * m_gamma;

            invM       += m_gamma;
            m_mass.ez.z = invM != 0.0f ? 1.0f / invM : 0.0f;
        }
        else if (K.ez.z == 0.0f)
        {
            K.GetInverse22(&m_mass);
            m_gamma = 0.0f;
            m_bias  = 0.0f;
        }
        else
        {
            K.GetSymInverse33(&m_mass);
            m_gamma = 0.0f;
            m_bias  = 0.0f;
        }

        if (data.step.warmStarting)
        {
            // Scale impulses to support a variable time step.
            m_impulse *= data.step.dtRatio;

            b2Vec2 P = b2Vec2(m_impulse.x, m_impulse.y);

            vA -= mA * P;
            wA -= iA * (b2Cross(m_rA, P) + m_impulse.z);

            vB += mB * P;
            wB += iB * (b2Cross(m_rB, P) + m_impulse.z);
        }
        else
        {
            m_impulse.SetZero();
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

        float32 mA = m_invMassA, mB = m_invMassB;
        float32 iA = m_invIA, iB = m_invIB;

        if (m_frequencyHz > 0.0f)
        {
            float32 Cdot2 = wB - wA;

            float32 impulse2 = -m_mass.ez.z * (Cdot2 + m_bias + m_gamma * m_impulse.z);
            m_impulse.z += impulse2;

            wA -= iA * impulse2;
            wB += iB * impulse2;

            b2Vec2 Cdot1 = vB + b2Cross(wB, m_rB) - vA - b2Cross(wA, m_rA);

            b2Vec2 impulse1 = -b2Mul22(m_mass, Cdot1);
            m_impulse.x += impulse1.x;
            m_impulse.y += impulse1.y;

            b2Vec2 P = impulse1;

            vA -= mA * P;
            wA -= iA * b2Cross(m_rA, P);

            vB += mB * P;
            wB += iB * b2Cross(m_rB, P);
        }
        else
        {
            b2Vec2  Cdot1 = vB + b2Cross(wB, m_rB) - vA - b2Cross(wA, m_rA);
            float32 Cdot2 = wB - wA;
            b2Vec3  Cdot = b2Vec3(Cdot1.x, Cdot1.y, Cdot2);

            b2Vec3 impulse = -b2Mul(m_mass, Cdot);
            m_impulse += impulse;

            b2Vec2 P = b2Vec2(impulse.x, impulse.y);

            vA -= mA * P;
            wA -= iA * (b2Cross(m_rA, P) + impulse.z);

            vB += mB * P;
            wB += iB * (b2Cross(m_rB, P) + impulse.z);
        }

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

        float32 mA = m_invMassA, mB = m_invMassB;
        float32 iA = m_invIA, iB = m_invIB;

        b2Vec2 rA = b2Mul(qA, m_localAnchorA - m_localCenterA);
        b2Vec2 rB = b2Mul(qB, m_localAnchorB - m_localCenterB);

        float32 positionError = 0, angularError = 0;

        b2Mat33 K;
        K.ex.x = mA + mB + rA.y * rA.y * iA + rB.y * rB.y * iB;
        K.ey.x = -rA.y * rA.x * iA - rB.y * rB.x * iB;
        K.ez.x = -rA.y * iA - rB.y * iB;
        K.ex.y = K.ey.x;
        K.ey.y = mA + mB + rA.x * rA.x * iA + rB.x * rB.x * iB;
        K.ez.y = rA.x * iA + rB.x * iB;
        K.ex.z = K.ez.x;
        K.ey.z = K.ez.y;
        K.ez.z = iA + iB;

        if (m_frequencyHz > 0.0f)
        {
            b2Vec2 C1 =  cB + rB - cA - rA;

            positionError = C1.Length();
            angularError  = 0.0f;

            b2Vec2 P = -K.Solve22(C1);

            cA -= mA * P;
            aA -= iA * b2Cross(rA, P);

            cB += mB * P;
            aB += iB * b2Cross(rB, P);
        }
        else
        {
            b2Vec2  C1 =  cB + rB - cA - rA;
            float32 C2 = aB - aA - m_referenceAngle;

            positionError = C1.Length();
            angularError  = b2Abs(C2);

            b2Vec3 C = b2Vec3(C1.x, C1.y, C2);

            b2Vec3 impulse;

            if (K.ez.z > 0.0f)
            {
                impulse = -K.Solve33(C);
            }
            else
            {
                b2Vec2 impulse2 = -K.Solve22(C1);
                impulse.Set(impulse2.x, impulse2.y, 0.0f);
            }

            b2Vec2 P = b2Vec2(impulse.x, impulse.y);

            cA -= mA * P;
            aA -= iA * (b2Cross(rA, P) + impulse.z);

            cB += mB * P;
            aB += iB * (b2Cross(rB, P) + impulse.z);
        }

        data.positions[m_indexA].c = cA;
        data.positions[m_indexA].a = aA;
        data.positions[m_indexB].c = cB;
        data.positions[m_indexB].a = aB;

        return positionError <= b2_linearSlop && angularError <= b2_angularSlop;
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
        b2Vec2 P = b2Vec2(m_impulse.x, m_impulse.y);
        return inv_dt * P;
    }

    override float32 GetReactionTorque(float32 inv_dt) const
    {
        return inv_dt * m_impulse.z;
    }

    override void Dump()
    {
        int32 indexA = m_body_A.m_islandIndex;
        int32 indexB = m_body_B.m_islandIndex;

        b2Log("  b2WeldJointDef jd;\n");
        b2Log("  jd.body_A = bodies[%d];\n", indexA);
        b2Log("  jd.body_B = bodies[%d];\n", indexB);
        b2Log("  jd.collideConnected = bool(%d);\n", m_collideConnected);
        b2Log("  jd.localAnchorA.Set(%.15lef, %.15lef);\n", m_localAnchorA.x, m_localAnchorA.y);
        b2Log("  jd.localAnchorB.Set(%.15lef, %.15lef);\n", m_localAnchorB.x, m_localAnchorB.y);
        b2Log("  jd.referenceAngle = %.15lef;\n", m_referenceAngle);
        b2Log("  jd.frequencyHz = %.15lef;\n", m_frequencyHz);
        b2Log("  jd.dampingRatio = %.15lef;\n", m_dampingRatio);
        b2Log("  joints[%d] = m_world.CreateJoint(&jd);\n", m_index);
    }

    /// The local anchor point relative to body_A's origin.
    b2Vec2 GetLocalAnchorA() const
    {
        return m_localAnchorA;
    }

    /// The local anchor point relative to body_B's origin.
    b2Vec2 GetLocalAnchorB() const
    {
        return m_localAnchorB;
    }

    /// Get the reference angle.
    float32 GetReferenceAngle() const
    {
        return m_referenceAngle;
    }

    /// Set/get frequency in Hz.
    void SetFrequency(float32 hz)
    {
        m_frequencyHz = hz;
    }

    float32 GetFrequency() const
    {
        return m_frequencyHz;
    }

    /// Set/get damping ratio.
    void SetDampingRatio(float32 ratio)
    {
        m_dampingRatio = ratio;
    }

    float32 GetDampingRatio() const
    {
        return m_dampingRatio;
    }

    float32 m_frequencyHz = 0;
    float32 m_dampingRatio = 0;
    float32 m_bias = 0;

    // Solver shared
    b2Vec2  m_localAnchorA;
    b2Vec2  m_localAnchorB;
    float32 m_referenceAngle = 0;
    float32 m_gamma = 0;
    b2Vec3  m_impulse;

    // Solver temp
    int32   m_indexA;
    int32   m_indexB;
    b2Vec2  m_rA;
    b2Vec2  m_rB;
    b2Vec2  m_localCenterA;
    b2Vec2  m_localCenterB;
    float32 m_invMassA = 0;
    float32 m_invMassB = 0;
    float32 m_invIA = 0;
    float32 m_invIB = 0;
    b2Mat33 m_mass;
}

import dbox.dynamics.joints.b2weldjoint;
import dbox.dynamics.b2body;
import dbox.dynamics.b2timestep;