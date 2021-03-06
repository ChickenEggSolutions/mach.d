module mach.sdl.graphics.primitives;

private:

import derelict.sdl2.sdl;
import derelict.opengl3.gl;

import mach.math : Vector2, isVector2, Vector3, isVector3, Box, isBox;

import mach.sdl.error : GLError;
import mach.sdl.window : Window;
import mach.sdl.graphics.color : Color;


import mach.io.log;

public:



void glVertex(T)(T x, T y){
    static if(is(T == short)) alias impl = glVertex2s;
    else static if(is(T == int)) alias impl = glVertex2i;
    else static if(is(T == float)) alias impl = glVertex2f;
    else static if(is(T == double)) alias impl = glVertex2d;
    else alias impl = void;
    static if(!is(impl == void)){
        impl(x, y);
    }else static if(isIntegral!T){
        glVertex3i(cast(int) x, cast(int) y);
    }else{
        glVertex3d(cast(double) x, cast(double) y);
    }
}
void glVertex(T)(T x, T y, T z){
    static if(is(T == short)) alias impl = glVertex3s;
    else static if(is(T == int)) alias impl = glVertex3i;
    else static if(is(T == float)) alias impl = glVertex3f;
    else static if(is(T == double)) alias impl = glVertex3d;
    else alias impl = void;
    static if(!is(impl == void)){
        impl(x, y, z);
    }else static if(isIntegral!T){
        glVertex3i(cast(int) x, cast(int) y, cast(int) z);
    }else{
        glVertex3d(cast(double) x, cast(double) y, cast(double) z);
    }
}


void glset(V)(V vector) if(isVector2!V){
    glVertex(vector.x, vector.y);
}

void glset(V)(V vector) if(isVector3!V){
    glVertex(vector.x, vector.y, vector.z);
}



auto primitives(uint mode, C, T)(Color!C color, Vector2!T[] vectors...){
    if(vectors && vectors.length){
        scope(exit) GLError.enforce();
        color.glset();
        glBegin(mode);
        foreach(vector; vectors) vector.glset();
        glEnd();
    }
}




// Reference: https://www.opengl.org/sdk/docs/man2/xhtml/glBegin.xml
// Note: Remember to use glLineWidth somewhere

auto points(C, T)(Color!C color, Vector2!T[] vectors...){
    primitives!GL_POINTS(color, vectors);
}

auto lines(C, T)(Color!C color, Vector2!T[] vectors...) in{
    assert(vectors.length >= 2 && vectors.length % 2 == 0);
}body{
    primitives!GL_LINES(color, vectors);
}

auto linestrip(C, T)(Color!C color, Vector2!T[] vectors...) in{
    assert(vectors.length >= 2);
}body{
    primitives!GL_LINE_STRIP(color, vectors);
}

auto lineloop(C, T)(Color!C color, Vector2!T[] vectors...) in{
    assert(vectors.length >= 2);
}body{
    primitives!GL_LINE_LOOP(color, vectors);
}

auto triangles(C, T)(Color!C color, Vector2!T[] vectors...) in{
    assert(vectors.length >= 3 && vectors.length % 3 == 0);
}body{
    primitives!GL_TRIANGLES(color, vectors);
}

auto trianglestrip(C, T)(Color!C color, Vector2!T[] vectors...) in{
    assert(vectors.length >= 3);
}body{
    primitives!GL_TRIANGLE_STRIP(color, vectors);
}

auto trianglefan(C, T)(Color!C color, Vector2!T[] vectors...) in{
    assert(vectors.length >= 3);
}body{
    primitives!GL_TRIANGLE_FAN(color, vectors);
}

auto quads(C, T)(Color!C color, Vector2!T[] vectors...) in{
    assert(vectors.length >= 4 && vectors.length % 4 == 0);
}body{
    primitives!GL_QUADS(color, vectors);
}

auto quads(C, T)(Color!C color, Box!T[] quads...){
    Vector2!T[] vectors;
    vectors.reserve(quads.length * 4);
    foreach(quad; quads) vectors ~= quad.corners;
    quads(color, vectors);
}

auto quadstrip(C, T)(Color!C color, Vector2!T[] vectors...) in{
    assert(vectors.length >= 4);
}body{
    primitives!GL_QUAD_STRIP(color, vectors);
}

auto polygon(C, T)(Color!C color, Vector2!T[] vectors...){
    primitives!GL_POLYGON(color, vectors);
}
