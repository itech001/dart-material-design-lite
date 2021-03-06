import 'dart:html' as html;
import 'dart:math' as Math;

/// license
/// Copyright 2015 Google Inc. All Rights Reserved.
/// 
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
/// 
/// http://www.apache.org/licenses/LICENSE-2.0
/// 
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.

/// A component handler interface using the revealing module design pattern.
/// More details on this pattern design here:
/// https://github.com/jasonmayes/mdl-component-design-pattern
/// author Jason Mayes.

final componentHandler = ( /*function*/ () {

  final registeredComponents_ = [];

  final createdComponents_ = [];

  final downgradeMethod_ = 'mdlDowngrade_';

  final componentConfigProperty_ = 'mdlComponentConfigInternal_';

/// Searches registered components for a class we are interested in using.
/// Optionally replaces a match with passed object if specified.
/// param {string} name The name of a class we want to use.
/// param {object} optReplace Optional object to replace match with.
/// return {object | false}
  function findRegisteredClass_(name, optReplace) {

    for (final i = 0; i < registeredComponents_.length; i++) {
      if (registeredComponents_[i].className == name) {
        if (optReplace != undefined) {
          registeredComponents_[i] = optReplace;
        }
        return registeredComponents_[i];
      }
    }
    return false;
  }

/// Searches existing DOM for elements of our component type and upgrades them
/// if they have not already been upgraded.
/// param {string} jsClass the programatic name of the element class we need
/// to create a new instance of.
/// param {string} cssClass the name of the CSS class elements of this type
/// will have.
  function upgradeDomInternal(jsClass, cssClass) {
    if (jsClass == undefined && cssClass == undefined) {

      for (final i = 0; i < registeredComponents_.length; i++) {
        upgradeDomInternal(registeredComponents_[i].className,
            registeredComponents_[i].cssClass);
      }

    } else {
      if (cssClass == undefined) {

        final registeredClass = findRegisteredClass_(jsClass);
        if (registeredClass) {
          cssClass = registeredClass.cssClass;
        }
      }

      final elements = document.querySelectorAll('.' + cssClass);

      for (final n = 0; n < elements.length; n++) {
        upgradeElementInternal(elements[n], jsClass);
      }
    }
  }

/// Upgrades a specific element rather than all in the DOM.
/// param {HTMLElement} element The element we wish to upgrade.
/// param {string} jsClass The name of the class we want to upgrade
/// the element to.
  function upgradeElementInternal(element, jsClass) {
    // Only upgrade elements that have not already been upgraded.

    final dataUpgraded = element.getAttribute('data-upgraded');

    if (dataUpgraded == null || dataUpgraded.indexOf(jsClass) == -1) {
      // Upgrade element.
      if (dataUpgraded == null) {
        dataUpgraded = '';
      }
      element.setAttribute('data-upgraded', dataUpgraded + ',' + jsClass);

      final registeredClass = findRegisteredClass_(jsClass);
      if (registeredClass) {
        // new

        final instance = new registeredClass.classConstructor(element);
        instance[componentConfigProperty_] = registeredClass;
        createdComponents_.push(instance);
        // Call any callbacks the user has registered with this component type.
        registeredClass.callbacks.forEach(function(callback) {
          callback(element);
        });

        if (registeredClass.widget) {
          // Assign per element instance for control over API
          element[jsClass] = instance;
        }

      } else {
        throw 'Unable to find a registered component for the given class.';
      }

      final ev = document.createEvent('Events');
      ev.initEvent('mdl-componentupgraded', true, true);
      element.dispatchEvent(ev);
    }
  }

/// Registers a class for future use and attempts to upgrade existing DOM.
/// param {object} config An object containing:
/// constructor: Constructor, classAsString: string, cssClass: string}
  function registerInternal(config) {

    final newConfig = {
      'classConstructor': config.constructor,
      'className': config.classAsString,
      'cssClass': config.cssClass,
      'widget': config.widget == undefined ? true : config.widget,
      'callbacks': []
    }

    registeredComponents_.forEach(function(item) {
      if (item.cssClass == newConfig.cssClass) {
        throw 'The provided cssClass has already been registered.';
      }
      if (item.className == newConfig.className) {
        throw 'The provided className has already been registered';
      }
    });

    if (config.constructor.prototype
        .hasOwnProperty(componentConfigProperty_)) {
      throw 'MDL component classes must not have ' + componentConfigProperty_ +
          ' defined as a property.';
    }

    final found = findRegisteredClass_(config.classAsString, newConfig);

    if (!found) {
      registeredComponents_.push(newConfig);
    }
  }

/// Allows user to be alerted to any upgrades that are performed for a given
/// component type
/// param {string} jsClass The class name of the MDL component we wish
/// to hook into for any upgrades performed.
/// param {function} callback The function to call upon an upgrade. This
/// function should expect 1 parameter - the HTMLElement which got upgraded.
  function registerUpgradedCallbackInternal(jsClass, callback) {

    final regClass = findRegisteredClass_(jsClass);
    if (regClass) {
      regClass.callbacks.push(callback);
    }
  }

/// Upgrades all registered components found in the current DOM. This is
/// automatically called on window load.
  function upgradeAllRegisteredInternal() {

    for (final n = 0; n < registeredComponents_.length; n++) {
      upgradeDomInternal(registeredComponents_[n].className);
    }
  }

/// Finds a created component by a given DOM node.
/// 
/// param {!Element} node
/// return {*}
  function findCreatedComponentByNodeInternal(node) {

    for (final n = 0; n < createdComponents_.length; n++) {

      final component = createdComponents_[n];
      if (component.element_ == node) {
        return component;
      }
    }
  }

/// Check the component for the downgrade method.
/// Execute if found.
/// Remove component from createdComponents list.
/// 
/// param {*} component
  function deconstructComponentInternal(component) {
    if (component &&
        component[componentConfigProperty_]
          .classConstructor.prototype
          .hasOwnProperty(downgradeMethod_)) {
      component[downgradeMethod_]();

      final componentIndex = createdComponents_.indexOf(component);
      createdComponents_.splice(componentIndex, 1);

      final upgrades = component._element.dataset.upgraded.split(',');

      final componentPlace = upgrades.indexOf(
          component[componentConfigProperty_].classAsString);
      upgrades.splice(componentPlace, 1);
      component._element.dataset.upgraded = upgrades.join(',');

      final ev = document.createEvent('Events');
      ev.initEvent('mdl-componentdowngraded', true, true);
      component._element.dispatchEvent(ev);
    }
  }

/// Downgrade either a given node, an array of nodes, or a NodeList.
/// 
/// param {*} nodes
  function downgradeNodesInternal(nodes) {

    final downgradeNode = function(node) {
      deconstructComponentInternal(findCreatedComponentByNodeInternal(node));
    }
    if (nodes instanceof Array || nodes instanceof NodeList) {

      for (final n = 0; n < nodes.length; n++) {
        downgradeNode(nodes[n]);
      }
    } else if (nodes instanceof Node) {
      downgradeNode(nodes);

    } else {
      throw 'Invalid argument provided to downgrade MDL nodes.';
    }
  }

  // Now return the functions that should be made public with their publicly
  // facing names...
  return {
    upgradeDom: upgradeDomInternal,
    upgradeElement: upgradeElementInternal,
    upgradeAllRegistered: upgradeAllRegisteredInternal,
    registerUpgradedCallback: registerUpgradedCallbackInternal,
    register: registerInternal,
    downgradeElements: downgradeNodesInternal
  }
})();

window.addEventListener('load', /*function*/ () {

/// Performs a "Cutting the mustard" test. If the browser supports the features
/// tested, adds a mdl-js class to the <html> element. It then upgrades all MDL
/// components requiring JavaScript.
  if ('classList' in new html.DivElement() &&
      'querySelector' in document &&
      'addEventListener' in window && Array.prototype.forEach) {
    document.documentElement.classes.add('mdl-js');
    componentHandler.upgradeAllRegistered();

  } else {
    componentHandler.upgradeElement =
        componentHandler.register = /*function*/ () {}
  }
});
