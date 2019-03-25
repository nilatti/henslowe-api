import PropTypes from 'prop-types';
import React, { Component } from 'react'
import { Button, Glyphicon } from 'react-bootstrap'

import TheaterForm from './TheaterForm.js'

class TheaterFormToggle extends Component { //opens form for create action
  constructor (props) {
    super (props)
    this.state = {
      isOpen: this.props.isOpen,
    }
  }

  handleFormOpen = () => {
    this.setState({ isOpen: true })
  }
  handleFormClose = () => {
    this.setState({ isOpen: false })
  }
  handleFormSubmit = (theater) => {
    this.handleFormClose()
    this.props.onFormSubmit(theater)
  }

  render() {
    if (this.state.isOpen) {
      return (
        <TheaterForm
          birthdate={this.props.birthdate}
          deathdate={this.props.deathdate}
          first_name={this.props.first_name}
          gender={this.props.gender}
          id={this.props.id}
          last_name={this.props.last_name}
          middle_name={this.props.middle_name}
          nationality={this.props.nationality}
          onFormSubmit={this.handleFormSubmit}
          onFormClose={this.handleFormClose}
          plays={this.props.plays}
        />
      );
    } else {
      return (
        <div>
          <Button bsStyle="info"
            onClick={this.handleFormOpen}
          >
            <Glyphicon glyph='glyphicon glyphicon-plus' /> Add New Theater
          </Button>
        </div>
      );
    }
  }
}

TheaterFormToggle.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  onFormSubmit: PropTypes.func.isRequired,
}

export default TheaterFormToggle