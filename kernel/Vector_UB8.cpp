// Vector_UB8.cpp
//
// Copyright (C) 2006-2011 Peter Graves <gnooth@gmail.com>
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

#include "lisp.hpp"
#include "SimpleArray_UB8_1.hpp"

Vector_UB8::Vector_UB8(INDEX capacity, Value fill_pointer)
  : AbstractVector(WIDETAG_VECTOR_UB8, capacity), _array(NULL), _offset(0)
{
  if (fill_pointer == NIL)
    {
      _has_fill_pointer = false;
      _fill_pointer = 0;
    }
  else
    {
      _has_fill_pointer = true;
      _fill_pointer = (fill_pointer == T) ? capacity : check_index(fill_pointer, 0, capacity);
    }
  _data = (unsigned char *) GC_malloc_atomic_ignore_off_page(capacity);
  for (INDEX i = 0; i < capacity; i++)
    _data[i] = 0;
}

// displaced
Vector_UB8::Vector_UB8(INDEX capacity, AbstractArray * array, INDEX offset, Value fill_pointer)
  : AbstractVector(WIDETAG_VECTOR_T, capacity), _data(NULL), _array(array), _offset(offset)
{
  if (fill_pointer == NIL)
    {
      _has_fill_pointer = false;
      _fill_pointer = 0;
    }
  else
    {
      _has_fill_pointer = true;
      _fill_pointer = (fill_pointer == T) ? capacity : check_index(fill_pointer, 0, capacity);
    }
}

Value Vector_UB8::element_type() const
{
  return UB8_TYPE;
}

Value Vector_UB8::type_of() const
{
  return list3(S_vector, UB8_TYPE, make_fixnum(_capacity));
}

bool Vector_UB8::typep(Value type) const
{
  if (consp(type))
    {
      Value type_specifier_atom = xcar(type);
      Value tail = xcdr(type);
      if (type_specifier_atom == S_array)
        {
          if (consp(tail))
            {
              Value element_type = xcar(tail);
              if (element_type == UNSPECIFIED)
                ; // ok
              else
                {
                  Value upgraded_element_type = upgraded_array_element_type(element_type);
                  if (::equal(upgraded_element_type, UB8_TYPE))
                    ; // ok
                  else if (::equal(upgraded_element_type,
                                   list3(S_integer, FIXNUM_ZERO, make_fixnum(255))))
                    ; // ok
                  else if (::equal(upgraded_element_type,
                                   list3(S_integer, FIXNUM_ZERO, list1(make_fixnum(256)))))
                    ; // ok
                  else
                    return false;
                }
              tail = xcdr(tail);
              if (tail == NIL)
                return true;
              if (cdr(tail) == NIL) // i.e. length(tail) == 1
                {
                  Value dimensions = xcar(tail);
                  if (dimensions == UNSPECIFIED)
                    return true;
                  if (dimensions == FIXNUM_ONE)
                    return true;
                  if (::equal(dimensions, list1(UNSPECIFIED)))
                    return true;
                  if (::equal(dimensions, list1(make_fixnum(_capacity))))
                    return true;
                }
            }
        }
    }
  else if (symbolp(type))
    {
      if (type == S_vector || type == S_sequence || type == S_simple_array
          || type == S_array || type == S_atom || type == T)
        return true;
    }
  else
    {
      if (type == C_vector || type == C_array || type == C_sequence || type == C_t)
        return true;
    }
  return false;
}

// FIXME enforce array-dimension-limit
// FIXME not thread-safe
void Vector_UB8::ensure_capacity(INDEX n)
{
  if (_data)
    {
      if (_capacity < n)
        {
          // FIXME check for overflow
          INDEX new_capacity = _capacity * 2;
          if (new_capacity < n)
            new_capacity = n;
          BYTE * new_data =
            (BYTE *) GC_malloc_atomic_ignore_off_page(new_capacity * sizeof(BYTE));
          INDEX i;
          INDEX limit = length();
          for (i = 0; i < limit; i++)
            new_data[i] = _data[i];
          while (i < new_capacity)
            new_data[i++] = 0;
          BYTE * old_data = _data;
          _data = new_data;
          _capacity = new_capacity;
          GC_free(old_data);
        }
    }
  else
    {
      // displaced
      if (_capacity < n || _array->total_size() - _offset < n)
        {
          // copy array
          // FIXME check for overflow
          INDEX new_capacity = _capacity * 2;
          if (new_capacity < n)
            new_capacity = n;
          _data = (unsigned char *) GC_malloc_atomic_ignore_off_page(new_capacity * sizeof(unsigned char));
          INDEX limit = _capacity;
          if (limit > _array->total_size() - _offset)
            limit = _array->total_size() - _offset;
          for (INDEX i = 0; i < limit; i++)
            {
              _data[i] = _array->aref(i + _offset);
            }
          _capacity = new_capacity;
          _array = NULL;
          _offset = 0;
        }
    }
}

void Vector_UB8::fill(Value value)
{
  long n = fixnum_value(value);
  if (n >= 0 && n < 256)
    {
      if (_data)
        {
          for (INDEX i = 0; i < _capacity; i++)
            _data[i] = n;
        }
      else
        {
          for (INDEX i = 0; i < _capacity; i++)
            aset(i, value);
        }
    }
  else
    signal_type_error(value, UB8_TYPE);
}

Value Vector_UB8::displacement() const
{
  return current_thread()->set_values(_array != NULL ? make_value(_array) : NIL,
                                      make_fixnum(_offset));
}

// "AREF ignores fill pointers. It is permissible to use AREF to access any
// array element, whether active or not."
Value Vector_UB8::aref(INDEX i) const
{
  if (i >= _capacity)
    return bad_index(i);
  if (_data)
    return make_fixnum(_data[i]);
  else
    // displaced
    return _array->aref(i + _offset);
}

Value Vector_UB8::aset(INDEX i, Value new_value)
{
  if (i >= _capacity)
    return bad_index(i);
  if (_data)
    {
      if (fixnump(new_value))
        {
          long n = xlong(new_value);
          if (n >= 0 && n < 256)
            {
              _data[i] = (unsigned char) n;
              return new_value;
            }
        }
      return signal_type_error(new_value, UB8_TYPE);
    }
  else
    // displaced
    return _array->aset(i + _offset, new_value);
}

Value Vector_UB8::elt(INDEX i) const
{
  if (i >= length())
    return bad_index(i);
  if (_data)
    return make_fixnum(_data[i]);
  else
    // displaced
    return _array->aref(i + _offset);
}

Value Vector_UB8::push(Value new_element)
{
  check_fill_pointer();
  long n = fixnum_value(new_element);
  if (n < 0 || n > 255)
    return signal_type_error(new_element, UB8_TYPE);
  if (_fill_pointer < _capacity)
    {
      INDEX old_fill_pointer = _fill_pointer;
      if (_data)
        _data[_fill_pointer] = (unsigned char) n;
      else
        // displaced
        _array->aset(_fill_pointer + _offset, new_element);
      ++_fill_pointer;
      return make_fixnum(old_fill_pointer);
    }
  else
    return NIL;
}

Value Vector_UB8::push_extend(Value new_element, INDEX extension)
{
  check_fill_pointer();
  long n = fixnum_value(new_element);
  if (n < 0 || n > 255)
    return signal_type_error(new_element, UB8_TYPE);
  if (_fill_pointer >= _capacity)
    ensure_capacity(_fill_pointer + extension);
  assert(_fill_pointer < _capacity);
  INDEX old_fill_pointer = _fill_pointer;
  if (_data)
    _data[_fill_pointer] = (unsigned char) n;
  else
    // displaced
    _array->aset(_fill_pointer + _offset, new_element);
  ++_fill_pointer;
  return make_fixnum(old_fill_pointer);
}

Value Vector_UB8::pop()
{
  check_fill_pointer();
  if (_fill_pointer > 0)
    {
      --_fill_pointer;
      if (_data)
        return make_fixnum(_data[_fill_pointer]);
      else
        return _array->aref(_fill_pointer + _offset);
    }
  else
    return signal_lisp_error("Nothing left to pop.");
}

Value Vector_UB8::reverse() const
{
  INDEX len = length();
  SimpleArray_UB8_1 * result = new_simple_array_ub8_1(len);
  unsigned char * data = result->data();
  INDEX i, j;
  if (_data)
    {
      for (i = 0, j = len - 1; i < len; i++, j--)
        data[i] = _data[j];
    }
  else
    {
      for (i = 0, j = len - 1; i < len; i++, j--)
        data[i] = fixnum_value(_array->aref(j + _offset));
    }
  return make_value(result);
}

Value Vector_UB8::nreverse()
{
  INDEX len = length();
  if (len > 0)
    {
      INDEX i = 0;
      INDEX j = len - 1;
      if (_data)
        {
          while (i < j)
            {
              Value temp = _data[i];
              _data[i] = _data[j];
              _data[j] = temp;
              ++i;
              --j;
            }
        }
      else
        {
          // displaced
          while (i < j)
            {
              Value temp = aref(i);;
              aset(i, aref(j));
              aset(j, temp);
              ++i;
              --j;
            }
        }
    }
  return make_value(this);
}

Value Vector_UB8::subseq(INDEX start, INDEX end) const
{
  assert(end >= start);
  const INDEX len = end - start;
  SimpleArray_UB8_1 * result = new_simple_array_ub8_1(len);
  unsigned char * data = result->data();
  INDEX i = start, j = 0;
  if (_data)
    {
      while (i < end)
        data[j++] = _data[i++];
    }
  else
    {
      // displaced
      while (i < end)
        data[j++] = fixnum_value(aref(i++));
    }
  return make_value(result);
}

AbstractVector * Vector_UB8::adjust_vector(INDEX new_capacity,
                                           Value initial_element,
                                           Value initial_contents)
{
  if (initial_contents != NIL)
    {
      // "If INITIAL-CONTENTS is supplied, it is treated as for MAKE-ARRAY.
      // In this case none of the original contents of array appears in the
      // resulting array."
      unsigned char * new_data =
        (unsigned char *) GC_malloc_atomic_ignore_off_page(new_capacity * sizeof(unsigned char));
      if (listp(initial_contents))
        {
          Value list = initial_contents;
          for (INDEX i = 0; i < new_capacity; i++)
            {
              long n = fixnum_value(car(list));
              if (n >= 0 && n < 256)
                new_data[i] = (unsigned char) n;
              else
                signal_type_error(car(list), UB8_TYPE);
              list = xcdr(list);
            }
        }
      else if (vectorp(initial_contents))
        {
          AbstractVector * v = the_vector(initial_contents);
          for (INDEX i = 0; i < new_capacity; i++)
            {
              long n = fixnum_value(v->aref(i));
              if (n >= 0 && n < 256)
                new_data[i] = (unsigned char) n;
              else
                signal_type_error(v->aref(i), UB8_TYPE);
            }
        }
      else
        signal_type_error(initial_contents, S_sequence);
      _data = new_data;
    }
  else
    {
      if (_data == NULL)
        {
          // displaced array
          _data = (unsigned char *) GC_malloc_atomic_ignore_off_page(new_capacity * sizeof(unsigned char));
          INDEX limit = (_capacity < new_capacity) ? _capacity : new_capacity;
          for (INDEX i = 0; i < limit; i++)
            {
              long n = fixnum_value(_array->aref(i + _offset));
              if (n >= 0 && n < 256)
                _data[i] = (unsigned char) n;
              else
                signal_type_error(_array->aref(i + _offset), UB8_TYPE);
            }
          long n = fixnum_value(initial_element);
          if (n >= 0 && n < 256)
            {
              for (INDEX i = _capacity; i < new_capacity; i++)
                _data[i] = initial_element;
            }
          else
            signal_type_error(initial_element, UB8_TYPE);
        }
      else if (_capacity != new_capacity)
        {
          unsigned char * new_data =
            (unsigned char *) GC_malloc_atomic_ignore_off_page(new_capacity * sizeof(unsigned char));
          INDEX limit = (_capacity < new_capacity) ? _capacity : new_capacity;
          for (INDEX i = 0; i < limit; i++)
            new_data[i] = _data[i];
          long n = fixnum_value(initial_element);
          if (n >= 0 && n < 256)
            {
              for (INDEX i = _capacity; i < new_capacity; i++)
                new_data[i] = initial_element;
            }
          else
            signal_type_error(initial_element, UB8_TYPE);
          _data = new_data;
        }
    }

  _capacity = new_capacity;

  // "The consequences are unspecified if array is adjusted to a size smaller
  // than its fill pointer without supplying the fill-pointer argument so that
  // its fill-pointer is properly adjusted in the process."
  if (_fill_pointer > _capacity)
    _fill_pointer = _capacity;

  _array = NULL;
  _offset = 0;

  return this;
}

AbstractVector * Vector_UB8::displace_vector(INDEX new_capacity,
                                             AbstractArray * displaced_to,
                                             INDEX offset)
{
  _capacity = new_capacity;

  // "The consequences are unspecified if array is adjusted to a size smaller
  // than its fill pointer without supplying the fill-pointer argument so that
  // its fill-pointer is properly adjusted in the process."
  if (_fill_pointer > _capacity)
    _fill_pointer = _capacity;

  _array = displaced_to;
  _offset = offset;
  _data = NULL;
  return this;
}
