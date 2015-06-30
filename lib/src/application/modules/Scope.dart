/**
 * Copyright (c) 2015, Michael Mitterer (office@mikemitterer.at),
 * IT-Consulting and Development Limited.
 * 
 * All Rights Reserved.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

part of mdlapplication;

Object mdlRootContext() {
    Object rootContext;
    try {
        rootContext = componentFactory().injector.getByKey(MDLROOTCONTEXT);
    }
    on Error {
        throw new ArgumentError("Could not find rootContext. "
        "Please define something like this: "
        "componentFactory().rootContext(AppController).run().then((_) { ... }");
    }
    return rootContext;
}

/// Looks for a SCOPE-AWARE!!!-Parent
Scope mdlParentScope(final MdlComponent component) {
  //Validate.isNotNull(component);

  if(component.parent == null) {
    return null;
  }
  if(component.parent is ScopeAware) {
    return (component.parent as ScopeAware).scope;
  }
  return mdlParentScope(component.parent);
}

abstract class ScopeAware {
    Scope get scope;
}

class Scope {
    final Logger _logger = new Logger('mdlapplication.Scope');

    final Scope _parentScope;

    Object _context;
    Object _rootContext;

    Scope(this._context,this._parentScope) {

    }

    Object get context => _context;
    void set context(final Object cntxt) {
      _context = cntxt;
    }

    Object get parentContext {
        if(_parentScope != null) {
            return _parentScope.context;
        }
        return rootContext;
    }

    Object get rootContext {
        if(_rootContext == null) {
            _rootContext = mdlRootContext();
        }
        return _rootContext;
    }

    //- private -----------------------------------------------------------------------------------
}

@di.Injectable()
class RootScope extends Scope {
    RootScope() : super(mdlRootContext(),null);
}