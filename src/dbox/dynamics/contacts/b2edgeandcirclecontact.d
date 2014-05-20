module dbox.dynamics.contacts.b2edgeandcirclecontact;

import core.stdc.float_;
import core.stdc.stdlib;
import core.stdc.string;

import dbox.common;
import dbox.collision.shapes;
import dbox.common.b2math;
import dbox.dynamics;
import dbox.collision;

/*
 * Copyright (c) 2006-2009 Erin Catto http://www.box2d.org
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

// #ifndef B2_EDGE_AND_CIRCLE_CONTACT_H
// #define B2_EDGE_AND_CIRCLE_CONTACT_H

import dbox.dynamics.contacts.b2contact;

class b2EdgeAndCircleContact : b2Contact
{
    static b2Contact Create(b2Fixture* fixtureA, int32, b2Fixture* fixtureB, int32, b2BlockAllocator* allocator)
    {
        //~ void* mem = allocator.Allocate(getSizeOf!b2EdgeAndCircleContact);
        //~ return emplace!b2EdgeAndCircleContact(mem, fixtureA, fixtureB);

        return new b2EdgeAndCircleContact(fixtureA, fixtureB);
    }

    static void Destroy(b2Contact contact, b2BlockAllocator* allocator)
    {
        typeid(cast(b2EdgeAndCircleContact)contact).destroy(&contact);
        allocator.Free(cast(void*)contact, getSizeOf!b2EdgeAndCircleContact);
    }

    this(b2Fixture* fixtureA, b2Fixture* fixtureB)
    {
        super(fixtureA, 0, fixtureB, 0);
        assert(m_fixtureA.GetType() == b2Shape.e_edge);
        assert(m_fixtureB.GetType() == b2Shape.e_circle);
    }

    override void Evaluate(b2Manifold* manifold, b2Transform xfA, b2Transform xfB)
    {
        b2CollideEdgeAndCircle(manifold,
                               cast(b2EdgeShape)m_fixtureA.GetShape(), xfA,
                               cast(b2CircleShape)m_fixtureB.GetShape(), xfB);
    }

}

// #endif
/*
 * Copyright (c) 2006-2010 Erin Catto http://www.box2d.org
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

import dbox.dynamics.contacts.b2edgeandcirclecontact;
import dbox.common.b2blockallocator;
import dbox.dynamics.b2fixture;

